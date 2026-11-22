-- The platform already has an active Super Admin. Permanently remove the one-time
-- bootstrap path so no account can claim Super Admin through a setup token.

BEGIN;

REVOKE ALL ON FUNCTION public.claim_initial_super_admin(text)
  FROM PUBLIC, anon, authenticated;

DROP FUNCTION IF EXISTS public.claim_initial_super_admin(text);

-- The setup secret table is now unused and was empty at migration time.
DROP TABLE IF EXISTS private.bootstrap_secrets;

COMMIT;
