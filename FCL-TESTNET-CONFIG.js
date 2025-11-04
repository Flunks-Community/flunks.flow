/**
 * FLUNKS HALLOWEEN GUMDROP - FCL Integration
 * Make sure this config is in your flunks-site frontend!
 */

import * as fcl from "@onflow/fcl";

// ========================================
// FCL CONFIGURATION - TESTNET
// ========================================

fcl.config({
  "app.detail.title": "Flunks Halloween GumDrop",
  "app.detail.icon": "https://flunks.io/logo.png",
  "accessNode.api": "https://rest-testnet.onflow.org", // TESTNET
  "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn", // TESTNET
  "0xSemesterZero": "0xb97ea2274b0ae5d2", // Your testnet contract
  "flow.network": "testnet"
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
// CHECK ELIGIBILITY
// ========================================

async function checkGumDropEligibility(userAddress) {
  const script = `
    import SemesterZero from 0xb97ea2274b0ae5d2

    access(all) fun main(user: Address): Bool {
      return SemesterZero.isEligibleForGumDrop(user: user)
    }
  `;

  try {
    const isEligible = await fcl.query({
      cadence: script,
      args: (arg, t) => [arg(userAddress, t.Address)]
    });
    
    return isEligible;
  } catch (error) {
    console.error("Error checking eligibility:", error);
    return false;
  }
}

// ========================================
// CLAIM GUMDROP (WITH TIMEZONE SETUP)
// ========================================

async function claimGumDrop(username) {
  const timezoneOffset = getTimezoneOffset();
  
  const transaction = `
    import SemesterZero from 0xb97ea2274b0ae5d2

    transaction(username: String, timezoneOffset: Int) {
      prepare(signer: auth(Storage, Capabilities) &Account) {
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
        
        assert(
          SemesterZero.isEligibleForGumDrop(user: signer.address),
          message: "You are not eligible for the active GumDrop or have already claimed"
        )
      }
      
      execute {
        log("GumDrop claim initiated")
      }
    }
  `;

  try {
    const transactionId = await fcl.mutate({
      cadence: transaction,
      args: (arg, t) => [
        arg(username, t.String),
        arg(timezoneOffset, t.Int)
      ],
      proposer: fcl.authz,
      payer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 9999
    });

    console.log("Transaction submitted:", transactionId);
    const result = await fcl.tx(transactionId).onceSealed();
    console.log("Transaction sealed:", result);

    return {
      success: true,
      transactionId,
      result
    };
  } catch (error) {
    console.error("Transaction error:", error);
    return {
      success: false,
      error: error.message
    };
  }
}

export { fcl, checkGumDropEligibility, claimGumDrop, getTimezoneOffset };
