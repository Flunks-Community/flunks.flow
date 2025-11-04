import SemesterZero from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

/// Claim GumDrop + Setup Timezone + Chapter 5 Collection (Combo Transaction)
/// Frontend auto-detects timezone using: new Date().getTimezoneOffset() / -60
/// This transaction sets up UserProfile + Chapter5Collection on first claim
/// 
/// Flow:
/// 1. User clicks pumpkin button during 72hr window
/// 2. Frontend detects timezone automatically
/// 3. User signs THIS transaction (setup profile + collection if first time)
/// 4. Backend receives confirmation, adds GUM to Supabase, calls markGumClaimed()
/// 
/// 💡 Complete Chapter 5 objectives for a special treat!
transaction(username: String, timezoneOffset: Int) {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if user already has profile
        let profileExists = signer.storage.borrow<&SemesterZero.UserProfile>(
            from: SemesterZero.UserProfileStoragePath
        ) != nil
        
        // If no profile, create one (first time claiming)
        if !profileExists {
            let profile <- SemesterZero.createUserProfile(
                username: username,
                timezone: timezoneOffset
            )
            
            // Save to storage
            signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
            
            // Link public capability (so Paradise Motel can read timezone)
            let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
                SemesterZero.UserProfileStoragePath
            )
            signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
        }
        
        // Setup Chapter 5 NFT collection if they don't have one yet
        // (Required to receive Chapter 5 completion NFT later!)
        let collectionExists = signer.storage.borrow<&SemesterZero.Chapter5Collection>(
            from: SemesterZero.Chapter5CollectionStoragePath
        ) != nil
        
        if !collectionExists {
            // Create empty collection
            let collection <- SemesterZero.createEmptyChapter5Collection()
            
            // Save to storage
            signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
            
            // Create public capability for receiving NFTs
            let nftCap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
                SemesterZero.Chapter5CollectionStoragePath
            )
            signer.capabilities.publish(nftCap, at: SemesterZero.Chapter5CollectionPublicPath)
        }
        
        // GumDrop claim - no eligibility check needed (frontend controls visibility)
        // Backend will verify and mark as claimed after transaction succeeds
    }
    
    execute {
        log("GumDrop claim initiated - backend will mark as claimed and add GUM to Supabase")
    }
}
