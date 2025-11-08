-- Query to find usernames for wallet addresses from paradise_motel_room7_visits
-- Run this in your Supabase SQL editor: https://supabase.com/dashboard/project/jejycbxxdsrcsobmvbbz/sql

-- First, let's see what columns are in paradise_motel_room7_visits
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'paradise_motel_room7_visits'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Get all data for these specific wallet addresses
SELECT *
FROM paradise_motel_room7_visits
WHERE wallet_address IN (
  '0x92629c2a389dd8a8',
  '0x4ab2327b5e1f3ca1',
  '0xcc909f90cc840949',
  '0x6e5d12b1735caa83'
);

-- If paradise_motel_room7_visits has username column, this will work:
-- SELECT wallet_address, username, visited_at
-- FROM paradise_motel_room7_visits
-- WHERE wallet_address IN (
--   '0x92629c2a389dd8a8',
--   '0x4ab2327b5e1f3ca1',
--   '0xcc909f90cc840949',
--   '0x6e5d12b1735caa83'
-- );

-- If username is in a different table, join with users/profiles:
-- SELECT 
--   v.wallet_address,
--   u.username,
--   v.visited_at
-- FROM paradise_motel_room7_visits v
-- LEFT JOIN users u ON v.wallet_address = u.wallet_address
-- WHERE v.wallet_address IN (
--   '0x92629c2a389dd8a8',
--   '0x4ab2327b5e1f3ca1',
--   '0xcc909f90cc840949',
--   '0x6e5d12b1735caa83'
-- );
