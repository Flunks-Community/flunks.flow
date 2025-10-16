-- Track blockchain syncs for GUM balances
CREATE TABLE IF NOT EXISTS gum_blockchain_syncs (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  synced_balance BIGINT NOT NULL,
  tx_id VARCHAR(128),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(32) DEFAULT 'completed', -- 'pending', 'completed', 'failed'
  sync_type VARCHAR(32) DEFAULT 'manual', -- 'cron', 'auto', 'manual', 'milestone'
  error_message TEXT,
  FOREIGN KEY (wallet_address) REFERENCES user_gum_balances(wallet_address)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_syncs_wallet ON gum_blockchain_syncs(wallet_address);
CREATE INDEX IF NOT EXISTS idx_syncs_date ON gum_blockchain_syncs(synced_at DESC);
CREATE INDEX IF NOT EXISTS idx_syncs_status ON gum_blockchain_syncs(status);

-- View: Latest sync per user
CREATE OR REPLACE VIEW latest_gum_syncs AS
SELECT DISTINCT ON (wallet_address)
  wallet_address,
  synced_balance,
  tx_id,
  synced_at,
  status,
  sync_type
FROM gum_blockchain_syncs
ORDER BY wallet_address, synced_at DESC;

-- Function: Get users needing sync
CREATE OR REPLACE FUNCTION get_users_needing_sync()
RETURNS TABLE (
  wallet_address VARCHAR(64),
  current_balance BIGINT,
  last_synced_balance BIGINT,
  balance_diff BIGINT,
  last_sync_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.wallet_address,
    b.total_gum as current_balance,
    COALESCE(s.synced_balance, 0) as last_synced_balance,
    b.total_gum - COALESCE(s.synced_balance, 0) as balance_diff,
    s.synced_at as last_sync_date
  FROM user_gum_balances b
  LEFT JOIN latest_gum_syncs s ON b.wallet_address = s.wallet_address
  WHERE 
    b.total_gum > COALESCE(s.synced_balance, 0) -- Balance increased
    OR s.synced_at IS NULL -- Never synced
  ORDER BY balance_diff DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE gum_blockchain_syncs IS 'Tracks when GUM balances are synced from Supabase to blockchain';
COMMENT ON FUNCTION get_users_needing_sync IS 'Returns list of users whose Supabase balance is higher than blockchain balance';
