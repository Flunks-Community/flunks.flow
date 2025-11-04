/**
 * FLUNKS HALLOWEEN GUMDROP - FCL Integration
 * MAINNET CONFIGURATION
 */

import * as fcl from "@onflow/fcl";

// ========================================
// FCL CONFIGURATION - MAINNET
// ========================================

fcl.config({
  "app.detail.title": "Flunks Halloween GumDrop",
  "app.detail.icon": "https://flunks.io/logo.png",
  "accessNode.api": "https://rest-mainnet.onflow.org", // MAINNET
  "discovery.wallet": "https://fcl-discovery.onflow.org/authn", // MAINNET (no /testnet/)
  "0xSemesterZero": "0xce9dd43888d99574", // MAINNET - SemesterZero contract (NEW ADDRESS)
  "flow.network": "mainnet"
});

// ========================================
// HELPER: Auto-detect user's timezone
// ========================================

function getTimezoneOffset() {
  const offsetMinutes = new Date().getTimezoneOffset();
  const offsetHours = Math.round(offsetMinutes / -60);
  return offsetHours;
}

// ========================================
// CHECK IF GUMDROP IS ACTIVE
// ========================================

async function checkGumDropActive() {
  const script = `
    import SemesterZero from 0xce9dd43888d99574

    access(all) fun main(): AnyStruct? {
      return SemesterZero.activeGumDrop
    }
  `;

  try {
    const activeDrop = await fcl.query({
      cadence: script,
      args: () => []
    });
    
    return activeDrop !== null;
  } catch (error) {
    console.error('Error checking GumDrop:', error);
    return false;
  }
}

// ========================================
// CLAIM GUMDROP TRANSACTION
// ========================================

async function claimGumDrop(username, timezoneOffset) {
  const transaction = `
    import SemesterZero from 0xce9dd43888d99574
    import NonFungibleToken from 0x1d7e57aa55817448

    /// Claim GumDrop + Setup Timezone + Chapter 5 Collection
    /// 💡 Complete Chapter 5 objectives for a special treat!
    transaction(username: String, timezoneOffset: Int) {
      
      prepare(signer: auth(Storage, Capabilities) &Account) {
        // Setup UserProfile (if first time)
        let profileExists = signer.storage.borrow<&SemesterZero.UserProfile>(
          from: SemesterZero.UserProfileStoragePath
        ) != nil
        
        if !profileExists {
          let profile <- SemesterZero.createUserProfile(
            username: username,
            timezone: timezoneOffset
          )
          signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
          
          let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
            SemesterZero.UserProfileStoragePath
          )
          signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
        }
        
        // Setup Chapter 5 NFT Collection (if first time)
        let collectionExists = signer.storage.borrow<&SemesterZero.Chapter5Collection>(
          from: SemesterZero.Chapter5CollectionStoragePath
        ) != nil
        
        if !collectionExists {
          let collection <- SemesterZero.createEmptyChapter5Collection()
          signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
          
          let nftCap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
            SemesterZero.Chapter5CollectionStoragePath
          )
          signer.capabilities.publish(nftCap, at: SemesterZero.Chapter5CollectionPublicPath)
        }
        
        // GumDrop claim - no eligibility check (frontend controls visibility)
        // Backend will verify and mark as claimed after transaction succeeds
      }
      
      execute {
        log("GumDrop claim initiated - backend will mark as claimed and add GUM to Supabase")
      }
    }
  `;

  try {
    const txId = await fcl.mutate({
      cadence: transaction,
      args: (arg, t) => [
        arg(username, t.String),
        arg(timezoneOffset, t.Int)
      ],
      limit: 9999
    });

    console.log('Transaction submitted:', txId);
    await fcl.tx(txId).onceSealed();
    console.log('Transaction sealed!');
    
    return txId;
  } catch (error) {
    console.error('Error claiming GumDrop:', error);
    throw error;
  }
}

export { checkGumDropActive, claimGumDrop, getTimezoneOffset };
