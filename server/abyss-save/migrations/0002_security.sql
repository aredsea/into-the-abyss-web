-- Existing PIN hashes used 100000 iterations. Never reinterpret or discard them.
ALTER TABLE accounts ADD COLUMN pin_iterations INTEGER NOT NULL DEFAULT 100000;
ALTER TABLE accounts ADD COLUMN rank_best INTEGER NOT NULL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN rank_level INTEGER NOT NULL DEFAULT 1;
ALTER TABLE accounts ADD COLUMN rank_at INTEGER NOT NULL DEFAULT 0;
UPDATE accounts SET rank_at=created;
-- Previously published scores cannot serve as trusted progress baselines.
DELETE FROM ranks;
DELETE FROM rank_cache;
ALTER TABLE rank_cache ADD COLUMN lock_until INTEGER NOT NULL DEFAULT 0;
ALTER TABLE rank_cache ADD COLUMN generation INTEGER NOT NULL DEFAULT 0;
CREATE INDEX accounts_updated ON accounts(updated);
CREATE INDEX counters_minute ON counters(minute);
-- Last save + credential verifier only; no FK, no public read route.
-- Inactivity: 180 days by default, then 30 more days of recovery grace.
CREATE TABLE inactive_archives (
 code TEXT PRIMARY KEY,
 salt TEXT NOT NULL,
 pin_hash TEXT NOT NULL,
 pin_iterations INTEGER NOT NULL,
 rev INTEGER NOT NULL,
 payload TEXT NOT NULL,
 summary TEXT NOT NULL,
 saved INTEGER NOT NULL,
 archived INTEGER NOT NULL,
 expires INTEGER NOT NULL
);
CREATE INDEX inactive_archives_expires ON inactive_archives(expires);
