const OpenAI = require("openai");

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// No CORS headers on purpose: this API is called only by the native iOS app.
// Without CORS, browsers refuse cross-origin JS calls — one less abuse vector
// if the app secret ever leaks.
const BASE_HEADERS = {
  "Content-Type": "application/json; charset=utf-8",
};

const APP_SECRET = process.env.APP_SECRET;
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 60;
const rateLimitMap = new Map();

function sendJson(res, statusCode, payload, extraHeaders = {}) {
  res.writeHead(statusCode, { ...BASE_HEADERS, ...extraHeaders });
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

function parseModelJson(rawContent) {
  if (!rawContent || typeof rawContent !== "string") {
    throw new Error("Empty model response.");
  }

  const trimmed = rawContent.trim();
  const candidates = [trimmed];

  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenced && fenced[1]) {
    candidates.push(fenced[1].trim());
  }

  const jsonLike = trimmed.match(/\{[\s\S]*\}/);
  if (jsonLike) {
    candidates.push(jsonLike[0]);
  }

  for (const candidate of candidates) {
    try {
      return JSON.parse(candidate);
    } catch (_error) {
      // Keep trying the next candidate.
    }
  }

  throw new Error("Unable to parse model JSON.");
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

/// Several transcripts of the SAME audio, one per speech recognizer.
function validateCandidatePayload(payload) {
  if (!Array.isArray(payload.candidates)) return null;

  const candidates = [];
  for (const entry of payload.candidates.slice(0, 5)) {
    const lang = normalizeLanguage(entry && entry.lang);
    const text =
      entry && typeof entry.text === "string" ? entry.text.trim() : "";
    if (!lang || !text) continue;
    if (text.length > 500) {
      return { ok: false, error: "Text exceeds 500 characters." };
    }
    candidates.push({ lang, text });
  }

  const targetLang = normalizeLanguage(payload.targetLang);
  const homeLang = normalizeLanguage(payload.homeLang) || targetLang;

  if (candidates.length === 0 || !targetLang) {
    return {
      ok: false,
      error: "Missing required fields: candidates, targetLang.",
    };
  }

  return { ok: true, value: { candidates, targetLang, homeLang } };
}

/// Picks the transcript that is actually a sentence, then translates it.
///
/// Every candidate is the same audio decoded by a recognizer locked to a
/// different language, so all but one read as phonetic nonsense. Deciding that
/// is something a language model does reliably and recognizer confidence
/// scores do not.
async function translateFromCandidates({ candidates, targetLang, homeLang }) {
  const completion = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || "gpt-4o-mini",
    temperature: 0,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "You are given several transcripts of the SAME spoken audio. Each was produced by a speech recognizer locked to a different language, so at most one is a faithful transcription; the others are the same sounds forced into a language that was not spoken and read as nonsense or as words that do not form a sensible utterance. " +
          "Choose the transcript that is genuinely coherent and meaningful in its own language. " +
          "Translate the chosen transcript into targetLang. If the chosen transcript is already in targetLang, translate it into homeLang instead. " +
          "Return JSON only, with keys: detected (the language code of the chosen transcript, exactly as given), source (the chosen transcript), translation (the translated text), translation_language (the language code you translated into). No other keys, no commentary.",
      },
      {
        role: "user",
        content: JSON.stringify({ candidates, targetLang, homeLang }),
      },
    ],
  });

  const raw =
    completion.choices &&
    completion.choices[0] &&
    completion.choices[0].message &&
    completion.choices[0].message.content
      ? completion.choices[0].message.content
      : "";

  const parsed = parseModelJson(raw);
  const translation =
    typeof parsed.translation === "string" ? parsed.translation.trim() : "";
  const detected = normalizeLanguage(parsed.detected);
  const source = typeof parsed.source === "string" ? parsed.source.trim() : "";
  const translationLanguage =
    normalizeLanguage(parsed.translation_language) || targetLang;

  const offered = candidates.map((candidate) => candidate.lang);
  if (!translation || !offered.includes(detected)) {
    throw new Error("Model returned invalid candidate payload.");
  }

  return {
    detected,
    source,
    translation,
    translation_language: translationLanguage,
  };
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

async function translateText({ text, sourceLang, targetLang }) {
  const completion = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || "gpt-4o-mini",
    temperature: 0,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "Return JSON only with keys translation and detected. Decide whether the input text is written in sourceLang or targetLang, set detected to exactly that language value, and translate into the opposite language. Never output extra keys or commentary.",
      },
      {
        role: "user",
        content: JSON.stringify({
          text,
          sourceLang,
          targetLang,
          rules: {
            detected_must_be_one_of: [sourceLang, targetLang],
            translation_target:
              "If detected equals sourceLang, translate into targetLang. Otherwise translate into sourceLang.",
          },
        }),
      },
    ],
  });

  const raw =
    completion.choices &&
    completion.choices[0] &&
    completion.choices[0].message &&
    completion.choices[0].message.content
      ? completion.choices[0].message.content
      : "";

  const parsed = parseModelJson(raw);
  const translation =
    typeof parsed.translation === "string" ? parsed.translation.trim() : "";
  const detected = normalizeLanguage(parsed.detected);

  if (!translation || ![sourceLang, targetLang].includes(detected)) {
    throw new Error("Model returned invalid translation payload.");
  }

  return { translation, detected };
}

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    sendJson(
      res,
      405,
      { error: "Method Not Allowed" },
      { Allow: "POST" }
    );
    return;
  }

  if (!process.env.OPENAI_API_KEY) {
    sendJson(res, 500, { error: "OPENAI_API_KEY is not configured." });
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

    const candidateValidation = validateCandidatePayload(payload);
    if (candidateValidation) {
      if (!candidateValidation.ok) {
        sendJson(res, 400, { error: candidateValidation.error });
        return;
      }
      fallbackDetected = candidateValidation.value.candidates[0].lang;
      const result = await translateFromCandidates(candidateValidation.value);
      sendJson(res, 200, result);
      return;
    }

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

    if (message === "Invalid JSON body." || message === "Request body too large.") {
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
