-- Rollback migration 003

DROP TABLE IF EXISTS merkle_proofs;
DROP TABLE IF NOT EXISTS reward_entries;
DROP TABLE IF EXISTS reward_distributions;
