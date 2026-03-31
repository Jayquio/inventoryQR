-- Rename audit tables to transaction and update FKs, indexes, triggers
-- Assumes existing table: audit_log(id PK, userId FK, action, resource, timestamp)
-- Target: transaction_log

BEGIN;

-- 1) Rename table
ALTER TABLE audit_log RENAME TO transaction_log;

-- 2) Update foreign keys referencing audit_log (example: report.auditedBy -> transaction_log)
-- Replace constraint names as appropriate for your schema
-- Example:
-- ALTER TABLE report DROP CONSTRAINT report_auditedby_fkey;
-- ALTER TABLE report ADD CONSTRAINT report_transactionlog_fkey
--   FOREIGN KEY (auditedBy) REFERENCES transaction_log(id) ON DELETE SET NULL;

-- 3) Rename indexes
-- Example: audit_log_userid_idx -> transaction_log_userid_idx
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'audit_log_userid_idx') THEN
    ALTER INDEX audit_log_userid_idx RENAME TO transaction_log_userid_idx;
  END IF;
END $$;

-- 4) Rename triggers on audit_log
-- Example: audit_log_insert_trigger -> transaction_log_insert_trigger
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_log_insert_trigger') THEN
    ALTER TRIGGER audit_log_insert_trigger ON transaction_log RENAME TO transaction_log_insert_trigger;
  END IF;
END $$;

COMMIT;
