import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Setup user profile with timezone
/// Run once per user when they first sign up
transaction(username: String, timezone: Int) {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if profile already exists
        if signer.storage.borrow<&SemesterZero.UserProfile>(from: SemesterZero.UserProfileStoragePath) != nil {
            panic("Profile already exists")
        }
        
        // Create profile
        let profile <- SemesterZero.createUserProfile(username: username, timezone: timezone)
        
        // Save to storage
        signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
        
        // Create public capability
        let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
            SemesterZero.UserProfileStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
        
        log("Profile created for: ".concat(username))
        log("Timezone: ".concat(timezone.toString()))
    }
}
