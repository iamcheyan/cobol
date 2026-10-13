-- Incident INC-2026-002 incident material: the batch ledger schema that the
-- upstream DB group published.  NOTE: the course snapshot does NOT run a
-- real database; this DDL documents the declared contract and the
-- offline file store (lib/db.py + db/ledger.dat) emulates it.  A real
-- PostgreSQL execution is NOT verified by this course.
CREATE TABLE transaction_ledger (
    business_date     char(8)  NOT NULL,
    transaction_id    char(16) NOT NULL,
    account_id        char(10) NOT NULL,
    direction         char(1)  NOT NULL CHECK (direction IN ('C','D')),
    amount            numeric(13) NOT NULL,
    commit_id         char(16) NOT NULL,
    CONSTRAINT ux_ledger_key UNIQUE (business_date, transaction_id)
);

-- The unique constraint above is the contract: one transaction_id may be
-- applied at most once per business date.  The batch application path is
-- required to honour it and to fail the run when the delivered feed
-- violates it, never to silently apply the duplicate.
