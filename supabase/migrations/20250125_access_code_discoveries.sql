-- Create access_code_discoveries table
-- Tracks when users enter access codes (SLACKER, CGAF, etc.)

CREATE TABLE IF NOT EXISTS access_code_discoveries (
  id BIGSERIAL PRIMARY KEY,
  wallet_address TEXT NOT NULL,
  code_entered TEXT NOT NULL,
  success BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_access_code_wallet ON access_code_discoveries(wallet_address);
CREATE INDEX IF NOT EXISTS idx_access_code_code ON access_code_discoveries(code_entered);
CREATE INDEX IF NOT EXISTS idx_access_code_success ON access_code_discoveries(success);
CREATE INDEX IF NOT EXISTS idx_access_code_created ON access_code_discoveries(created_at);

-- Composite index for Chapter 5 eligibility checks
CREATE INDEX IF NOT EXISTS idx_access_code_chapter5 
  ON access_code_discoveries(wallet_address, code_entered, success);
