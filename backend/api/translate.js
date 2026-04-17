const AZURE_ENDPOINT =
  "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-App-Secret",
  "Content-Type": "application/json; charset=utf-8",
};

const APP_SECRET = process.env.APP_SECRET;
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 60;
const rateLimitMap = new Map();

function sendJson(res, statusCode, payload, extraHeaders = {}) {
  res.writeHead(statusCode, { ...CORS_HEADERS, ...extraHeaders });
  res.end(JSON.stringify(payload));
}

function parseRequestBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";

    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Request body too large."));
        req.destroy();
      }
    });

    req.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        reject(new Error("Invalid JSON body."));
      }
    });

    req.on("error", reject);
  });
}

function normalizeLanguage(value) {
  return String(value || "").trim();
}

function getClientIp(req) {
  const forwardedFor = req.headers["x-forwarded-for"];
  if (Array.isArray(forwardedFor)) {
    return forwardedFor[0];
  }
  if (typeof forwardedFor === "string" && forwardedFor.length > 0) {
    return forwardedFor.split(",")[0].trim();
  }
  return req.socket?.remoteAddress || "unknown";
}

function isRateLimited(ip) {
  const now = Date.now();
  const current = rateLimitMap.get(ip);

  if (!current || now > current.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }

  current.count += 1;
  rateLimitMap.set(ip, current);
  return current.count > RATE_LIMIT_MAX_REQUESTS;
}

function validatePayload(payload) {
  const text = typeof payload.text === "string" ? payload.text.trim() : "";
  const sourceLang = normalizeLanguage(payload.sourceLang);
  const targetLang = normalizeLanguage(payload.targetLang);

  if (!text || !sourceLang || !targetLang) {
    return {
      ok: false,
      error: "Missing required fields: text, sourceLang, targetLang.",
    };
  }

  if (text.length > 500) {
    return {
      ok: false,
      error: "Text exceeds 500 characters.",
    };
  }

  return {
    ok: true,
    value: { text, sourceLang, targetLang },
  };
}

// Map app language codes to Azure Translator language codes
function toAzureCode(code) {
  if (code === "zh") return "zh-Hans";
  if (code === "zh-TW") return "zh-Hant";
  return code;
}

// Match Azure's detected language code back to one of the app's language codes
function matchAzureDetected(azureCode, sourceLang, targetLang) {
  const azureSource = toAzureCode(sourceLang);
  const azureTarget = toAzureCode(targetLang);
  if (azureCode === azureSource || azureCode.startsWith(azureSource + "-")) {
    return sourceLang;
  }
  if (azureCode === azureTarget || azureCode.startsWith(azureTarget + "-")) {
    return targetLang;
  }
  return sourceLang; // fallback
}

async function translateText({ text, sourceLang, targetLang }) {
  const azureKey = process.env.AZURE_TRANSLATOR_KEY;
  const azureRegion = process.env.AZURE_TRANSLATOR_REGION;

  const azureSourceCode = toAzureCode(sourceLang);
  const azureTargetCode = toAzureCode(targetLang);

  // Request translations to both languages so Azure auto-detects the source
  // and we can pick the correct output without a second round-trip.
  const url =
    `${AZURE_ENDPOINT}` +
    `&to=${encodeURIComponent(azureSourceCode)}` +
    `&to=${encodeURIComponent(azureTargetCode)}`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Ocp-Apim-Subscription-Key": azureKey,
      "Ocp-Apim-Subscription-Region": azureRegion,
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify([{ Text: text }]),
  });

  if (!response.ok) {
    const errBody = await response.text().catch(() => "");
    throw new Error(`Azure Translator HTTP ${response.status}: ${errBody}`);
  }

  const data = await response.json();
  const item = data[0];

  if (!item || !Array.isArray(item.translations)) {
    throw new Error("Unexpected Azure Translator response shape.");
  }

  const azureDetected = item.detectedLanguage?.language || azureSourceCode;
  const detected = matchAzureDetected(azureDetected, sourceLang, targetLang);

  // Translate into the OTHER language from the one that was detected
  const translationTo =
    detected === sourceLang ? azureTargetCode : azureSourceCode;
  const entry = item.translations.find((t) => t.to === translationTo);
  const translation = entry?.text?.trim() || "";

  if (!translation) {
    throw new Error("Azure Translator returned empty translation.");
  }

  return { translation, detected };
}

module.exports = async (req, res) => {
  if (req.method === "OPTIONS") {
    res.writeHead(204, CORS_HEADERS);
    res.end();
    return;
  }

  if (req.method !== "POST") {
    sendJson(
      res,
      405,
      { error: "Method Not Allowed" },
      { Allow: "POST, OPTIONS" }
    );
    return;
  }

  if (!process.env.AZURE_TRANSLATOR_KEY) {
    sendJson(res, 500, { error: "AZURE_TRANSLATOR_KEY is not configured." });
    return;
  }

  if (!process.env.AZURE_TRANSLATOR_REGION) {
    sendJson(res, 500, { error: "AZURE_TRANSLATOR_REGION is not configured." });
    return;
  }

  if (!APP_SECRET) {
    sendJson(res, 500, { error: "APP_SECRET is not configured." });
    return;
  }

  if (req.headers["x-app-secret"] !== APP_SECRET) {
    sendJson(res, 401, { error: "unauthorized" });
    return;
  }

  const clientIp = getClientIp(req);
  if (isRateLimited(clientIp)) {
    sendJson(res, 429, { error: "rate_limited" });
    return;
  }

  let fallbackDetected = "";

  try {
    const payload = await parseRequestBody(req);
    const validation = validatePayload(payload);

    if (!validation.ok) {
      sendJson(res, 400, { error: validation.error });
      return;
    }

    fallbackDetected = validation.value.sourceLang;
    const result = await translateText(validation.value);
    sendJson(res, 200, result);
  } catch (error) {
    const message =
      error && error.message ? error.message : "Unexpected server error.";

    if (
      message === "Invalid JSON body." ||
      message === "Request body too large."
    ) {
      sendJson(res, 400, { error: message });
      return;
    }

    console.error("Translation error:", message);
    sendJson(res, 200, {
      error: "translation_failed",
      translation: "",
      detected: fallbackDetected,
    });
  }
};
