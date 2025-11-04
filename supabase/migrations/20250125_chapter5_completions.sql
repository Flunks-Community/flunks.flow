-- SQL Function: Get all wallets that completed BOTH Chapter 5 objectives
-- (Entered both SLACKER and CGAF codes successfully)

CREATE OR REPLACE FUNCTION get_chapter5_completions()
RETURNS TABLE(wallet_address TEXT, slacker_entered_at TIMESTAMP, cgaf_entered_at TIMESTAMP) AS $$
  SELECT 
    wallet_address,
    MAX(CASE WHEN code_entered = 'SLACKER' THEN created_at END) as slacker_entered_at,
    MAX(CASE WHEN code_entered = 'CGAF' THEN created_at END) as cgaf_entered_at
  FROM access_code_discoveries
  WHERE code_entered IN ('SLACKER', 'CGAF')
    AND success = true
  GROUP BY wallet_address
  HAVING COUNT(DISTINCT code_entered) = 2
  ORDER BY MAX(created_at) DESC
$$ LANGUAGE SQL;

-- Example query to see who's eligible:
-- SELECT * FROM get_chapter5_completions();
