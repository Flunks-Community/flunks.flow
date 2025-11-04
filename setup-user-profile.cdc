import SemesterZero from 0xce9dd43888d99574

/// Set up UserProfile for Paradise Motel day/night (without GumDrop claim)
/// This is for testing purposes
transaction(username: String, timezoneOffset: Int) {
    
    prepare(signer: auth(SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {
        // Check if profile already exists
        if signer.storage.borrow<&SemesterZero.UserProfile>(from: SemesterZero.UserProfileStoragePath) != nil {
            log("Profile already exists!")
            return
        }
        
        // Create user profile with timezone
        let profile <- SemesterZero.createUserProfile(
            username: username,
            timezone: timezoneOffset
        )
        
        // Save to storage
        signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
        
        // Create and publish capability
        let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
            SemesterZero.UserProfileStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
        
        log("✅ UserProfile created with timezone: ".concat(timezoneOffset.toString()))
    }
}
