-- GuardedReview audit log (PostgreSQL / Supabase)
-- Run once as the database owner. Change the password before running.

CREATE TABLE public.audit_log (
  event_id           BIGSERIAL PRIMARY KEY,
  pr_id              INTEGER NOT NULL,
  repo               TEXT NOT NULL,
  files_touched      JSONB,
  ai_output_hash     TEXT,
  redaction_summary  JSONB,
  approver_id        TEXT,
  decision           TEXT NOT NULL,
  decision_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  workflow_run_id    TEXT
);

-- Supabase only: keep the table off the public API
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.audit_log FROM anon, authenticated;
REVOKE ALL ON SEQUENCE public.audit_log_event_id_seq FROM anon, authenticated;

-- Login role for n8n: can add rows and read them, nothing else
CREATE ROLE n8n_audit_writer WITH LOGIN PASSWORD 'CHANGE_ME_TO_A_STRONG_PASSWORD';
GRANT USAGE ON SCHEMA public TO n8n_audit_writer;
GRANT INSERT, SELECT ON public.audit_log TO n8n_audit_writer;
GRANT USAGE ON SEQUENCE public.audit_log_event_id_seq TO n8n_audit_writer;
CREATE POLICY n8n_insert ON public.audit_log FOR INSERT TO n8n_audit_writer WITH CHECK (true);
CREATE POLICY n8n_read   ON public.audit_log FOR SELECT TO n8n_audit_writer USING (true);

-- Append-only for everyone, including the admin
CREATE OR REPLACE FUNCTION public.audit_log_block_changes()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append-only: % is not allowed', TG_OP;
END $$;

CREATE TRIGGER audit_log_no_update_delete
BEFORE UPDATE OR DELETE ON public.audit_log
FOR EACH ROW EXECUTE FUNCTION public.audit_log_block_changes();

CREATE TRIGGER audit_log_no_truncate
BEFORE TRUNCATE ON public.audit_log
FOR EACH STATEMENT EXECUTE FUNCTION public.audit_log_block_changes();

-- Check: the UPDATE below must fail with "audit_log is append-only"
-- INSERT INTO audit_log (pr_id, repo, decision) VALUES (0, 'test', 'test');
-- UPDATE audit_log SET decision = 'changed' WHERE pr_id = 0;
