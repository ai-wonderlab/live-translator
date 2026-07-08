# Account Deletion — Supabase Setup

Το app καλεί `supabase.rpc("delete_user")`. Χρειάζεται μία φορά αυτό το SQL στο Supabase dashboard (SQL Editor):

```sql
create or replace function public.delete_user()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = auth.uid();
$$;

-- Μόνο authenticated users μπορούν να το καλέσουν
revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;
```

Έλεγχος: sign in στο app → Profile → Delete Account → confirm → ο user πρέπει να εξαφανιστεί από Authentication → Users.

_Απαραίτητο για App Store Guideline 5.1.1(v): apps με account creation πρέπει να προσφέρουν account deletion μέσα στο app._
