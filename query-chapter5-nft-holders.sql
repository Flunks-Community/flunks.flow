-- Query to find who has Chapter 5 NFTs
-- These are users who completed both slacker and overachiever achievements

-- Check chapter5_completions table
SELECT 
  wallet_address,
  completed_at,
  slacker_nft_id,
  overachiever_nft_id
FROM chapter5_completions
WHERE slacker_nft_id IS NOT NULL 
   OR overachiever_nft_id IS NOT NULL
ORDER BY completed_at DESC;

-- If that doesn't exist, check for users who completed both achievements
-- SELECT 
--   u.wallet_address,
--   u.username,
--   COUNT(*) as achievement_count
-- FROM achievement_unlocks au
-- JOIN users u ON au.user_id = u.id
-- WHERE au.achievement_name IN ('slacker', 'overachiever')
-- GROUP BY u.wallet_address, u.username
-- HAVING COUNT(DISTINCT au.achievement_name) = 2;
