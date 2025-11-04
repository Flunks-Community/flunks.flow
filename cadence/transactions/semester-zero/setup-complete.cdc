import SemesterZero from "../contracts/SemesterZero.cdc"

/// Complete setup for a new Semester Zero user
/// Creates: Profile + GUM Account + Achievement Collection
transaction(username: String, timezone: Int) {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        
        // ========================================
        // 1. Create User Profile
        // ========================================
        if signer.storage.borrow<&SemesterZero.UserProfile>(from: SemesterZero.UserProfileStoragePath) == nil {
            let profile <- SemesterZero.createUserProfile(username: username, timezone: timezone)
            signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
            
            let profileCap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
                SemesterZero.UserProfileStoragePath
            )
            signer.capabilities.publish(profileCap, at: SemesterZero.UserProfilePublicPath)
            
            log("✅ Profile created: ".concat(username).concat(" (Timezone: ").concat(timezone.toString()).concat(")"))
        } else {
            log("⚠️  Profile already exists")
        }
        
        // ========================================
        // 2. Create GUM Account
        // ========================================
        if signer.storage.borrow<&SemesterZero.GumAccount>(from: SemesterZero.GumAccountStoragePath) == nil {
            let gumAccount <- SemesterZero.createGumAccount(initialBalance: 0.0)
            signer.storage.save(<-gumAccount, to: SemesterZero.GumAccountStoragePath)
            
            let gumCap = signer.capabilities.storage.issue<&SemesterZero.GumAccount>(
                SemesterZero.GumAccountStoragePath
            )
            signer.capabilities.publish(gumCap, at: SemesterZero.GumAccountPublicPath)
            
            log("✅ GUM Account created with 0.0 balance")
        } else {
            log("⚠️  GUM Account already exists")
        }
        
        // ========================================
        // 3. Create Achievement Collection
        // ========================================
        if signer.storage.borrow<&SemesterZero.AchievementCollection>(from: SemesterZero.AchievementCollectionStoragePath) == nil {
            let collection <- SemesterZero.createEmptyAchievementCollection()
            signer.storage.save(<-collection, to: SemesterZero.AchievementCollectionStoragePath)
            
            let collectionCap = signer.capabilities.storage.issue<&SemesterZero.AchievementCollection>(
                SemesterZero.AchievementCollectionStoragePath
            )
            signer.capabilities.publish(collectionCap, at: SemesterZero.AchievementCollectionPublicPath)
            
            log("✅ Achievement Collection created")
        } else {
            log("⚠️  Achievement Collection already exists")
        }
        
        log("🎉 Semester Zero setup complete!")
    }
    
    execute {
        log("Welcome to Semester Zero!")
    }
}
