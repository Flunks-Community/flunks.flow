// API Route: Mark Chapter 5 Objectives as Complete
// Called when user completes SLACKER or CGAF (Overachiever) in Supabase

import { createClient } from '@supabase/supabase-js'
import * as fcl from '@onflow/fcl'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // Admin key
)

// ========================================
// 1. CHECK CHAPTER 5 COMPLETION
// ========================================

export async function checkChapter5Completion(walletAddress: string) {
  // Check Slacker objective (SLACKER code)
  const { data: slackerCodes } = await supabase
    .from('access_code_discoveries')
    .select('*')
    .eq('wallet_address', walletAddress)
    .eq('code_entered', 'SLACKER')
    .eq('success', true)
    .limit(1)
  
  const slackerComplete = slackerCodes && slackerCodes.length > 0

  // Check Overachiever objective (CGAF code from Hidden Riff)
  const { data: overachieverCodes } = await supabase
    .from('access_code_discoveries')
    .select('*')
    .eq('wallet_address', walletAddress)
    .eq('code_entered', 'CGAF')
    .eq('success', true)
    .limit(1)
  
  const overachieverComplete = overachieverCodes && overachieverCodes.length > 0

  return {
    slackerComplete,
    overachieverComplete,
    fullyComplete: slackerComplete && overachieverComplete
  }
}

// ========================================
// 2. SYNC TO BLOCKCHAIN
// ========================================

export async function syncObjectiveToBlockchain(
  walletAddress: string,
  objective: 'slacker' | 'overachiever'
) {
  const adminAuthz = fcl.authz // Your admin authorization

  const transaction = objective === 'slacker'
    ? `
      import SemesterZero from 0x807c3d470888cc48
      
      transaction(userAddress: Address) {
        let adminRef: &SemesterZero.Admin
        
        prepare(signer: auth(Storage) &Account) {
          self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
          ) ?? panic("Could not borrow Admin reference")
        }
        
        execute {
          self.adminRef.registerSlackerCompletion(userAddress: userAddress)
          log("Slacker completion registered for: ".concat(userAddress.toString()))
        }
      }
    `
    : `
      import SemesterZero from 0x807c3d470888cc48
      
      transaction(userAddress: Address) {
        let adminRef: &SemesterZero.Admin
        
        prepare(signer: auth(Storage) &Account) {
          self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
          ) ?? panic("Could not borrow Admin reference")
        }
        
        execute {
          self.adminRef.registerOverachieverCompletion(userAddress: userAddress)
          log("Overachiever completion registered for: ".concat(userAddress.toString()))
        }
      }
    `

  const txId = await fcl.mutate({
    cadence: transaction,
    args: (arg, t) => [arg(walletAddress, t.Address)],
    authorizations: [adminAuthz],
    limit: 1000
  })

  await fcl.tx(txId).onceSealed()
  return txId
}

// ========================================
// 3. AUTO-AIRDROP NFT IF 100% COMPLETE
// ========================================

export async function checkAndAirdropChapter5NFT(walletAddress: string) {
  // Check blockchain eligibility
  const isEligible = await fcl.query({
    cadence: `
      import SemesterZero from 0x807c3d470888cc48
      
      access(all) fun main(userAddress: Address): Bool {
        return SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress)
      }
    `,
    args: (arg, t) => [arg(walletAddress, t.Address)]
  })

  if (!isEligible) {
    return { eligible: false, message: 'Not yet eligible for Chapter 5 NFT' }
  }

  // Check if user has Chapter 5 collection setup
  const hasCollection = await fcl.query({
    cadence: `
      import SemesterZero from 0x807c3d470888cc48
      
      access(all) fun main(userAddress: Address): Bool {
        return getAccount(userAddress)
          .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
          .check()
      }
    `,
    args: (arg, t) => [arg(walletAddress, t.Address)]
  })

  if (!hasCollection) {
    return { 
      eligible: true, 
      hasCollection: false,
      message: 'User needs to set up Chapter 5 collection first' 
    }
  }

  // Airdrop the NFT!
  const adminAuthz = fcl.authz

  const txId = await fcl.mutate({
    cadence: `
      import SemesterZero from 0x807c3d470888cc48
      
      transaction(userAddress: Address) {
        let adminRef: &SemesterZero.Admin
        
        prepare(signer: auth(Storage) &Account) {
          self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
          ) ?? panic("Could not borrow Admin reference")
        }
        
        execute {
          self.adminRef.airdropChapter5NFT(userAddress: userAddress)
          log("Chapter 5 NFT airdropped to: ".concat(userAddress.toString()))
        }
      }
    `,
    args: (arg, t) => [arg(walletAddress, t.Address)],
    authorizations: [adminAuthz],
    limit: 1000
  })

  await fcl.tx(txId).onceSealed()

  return {
    eligible: true,
    hasCollection: true,
    airdropped: true,
    txId
  }
}

// ========================================
// 4. WEBHOOK / CRON JOB HANDLER
// ========================================

// Call this when access_code_discoveries gets a new entry
export async function POST(req: Request) {
  const { walletAddress, codeEntered } = await req.json()

  // Verify it's a Chapter 5 code
  if (!['SLACKER', 'CGAF'].includes(codeEntered)) {
    return Response.json({ message: 'Not a Chapter 5 code' })
  }

  // Determine which objective was completed
  const objective = codeEntered === 'SLACKER' ? 'slacker' : 'overachiever'

  // Sync to blockchain
  const txId = await syncObjectiveToBlockchain(walletAddress, objective)

  // Check if both are now complete
  const completion = await checkChapter5Completion(walletAddress)

  if (completion.fullyComplete) {
    // Trigger NFT airdrop!
    const airdropResult = await checkAndAirdropChapter5NFT(walletAddress)
    
    return Response.json({
      objective,
      txId,
      fullyComplete: true,
      airdrop: airdropResult
    })
  }

  return Response.json({
    objective,
    txId,
    fullyComplete: false,
    slackerComplete: completion.slackerComplete,
    overachieverComplete: completion.overachieverComplete
  })
}

// ========================================
// 5. BULK AIRDROP (For existing completions)
// ========================================

export async function bulkAirdropChapter5NFTs() {
  // Get all wallets with BOTH codes
  const { data: eligibleWallets } = await supabase.rpc('get_chapter5_completions')
  
  // SQL function:
  // CREATE OR REPLACE FUNCTION get_chapter5_completions()
  // RETURNS TABLE(wallet_address TEXT) AS $$
  //   SELECT DISTINCT wallet_address
  //   FROM access_code_discoveries
  //   WHERE code_entered IN ('SLACKER', 'CGAF')
  //     AND success = true
  //   GROUP BY wallet_address
  //   HAVING COUNT(DISTINCT code_entered) = 2
  // $$ LANGUAGE SQL;

  const results = []

  for (const wallet of eligibleWallets || []) {
    try {
      // Register both objectives
      await syncObjectiveToBlockchain(wallet.wallet_address, 'slacker')
      await syncObjectiveToBlockchain(wallet.wallet_address, 'overachiever')
      
      // Airdrop NFT
      const result = await checkAndAirdropChapter5NFT(wallet.wallet_address)
      results.push({ wallet: wallet.wallet_address, ...result })
    } catch (error) {
      results.push({ wallet: wallet.wallet_address, error: error.message })
    }
  }

  return results
}
