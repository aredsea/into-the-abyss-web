PRAGMA foreign_keys = ON;
CREATE TABLE accounts (
 code TEXT PRIMARY KEY,
 salt TEXT NOT NULL,
 pin_hash TEXT NOT NULL,
 rev INTEGER NOT NULL DEFAULT 0,
 created INTEGER NOT NULL,
 updated INTEGER NOT NULL
);
CREATE TABLE saves (
 code TEXT NOT NULL REFERENCES accounts(code) ON DELETE CASCADE,
 rev INTEGER NOT NULL,
 payload TEXT NOT NULL CHECK(length(CAST(payload AS BLOB)) <= 65536),
 summary TEXT NOT NULL,
 created INTEGER NOT NULL,
 PRIMARY KEY(code,rev)
);
CREATE TABLE ranks (
 code TEXT PRIMARY KEY REFERENCES accounts(code) ON DELETE CASCADE,
 best INTEGER NOT NULL CHECK(best BETWEEN 1 AND 9999),
 updated INTEGER NOT NULL
);
CREATE INDEX ranks_best ON ranks(best DESC);
CREATE TABLE counters (
 bucket TEXT NOT NULL,
 minute INTEGER NOT NULL,
 n INTEGER NOT NULL,
 PRIMARY KEY(bucket,minute)
);
CREATE TABLE rank_cache (
 id INTEGER PRIMARY KEY CHECK(id=1),
 payload TEXT NOT NULL,
 expires INTEGER NOT NULL
);
-- The CAS UPDATE is the only writer. History is captured inside that same transaction.
CREATE TRIGGER retain_ten AFTER INSERT ON saves BEGIN
 DELETE FROM saves WHERE code=NEW.code AND rev<=NEW.rev-10;
END;
