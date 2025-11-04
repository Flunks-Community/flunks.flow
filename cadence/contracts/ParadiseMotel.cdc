import SemesterZero from "./SemesterZero.cdc"
// import MetadataViews from "./MetadataViews.cdc" // Optional: Uncomment if you need MetadataViews integration

/// Paradise Motel Dynamic Day/Night System
/// Uses Forte upgrade for dynamic metadata and 12-hour day/night cycles
/// Integrates with Supabase for image switching

access(all) contract ParadiseMotel {
    
    // ========================================
    // PATHS & CONSTANTS
    // ========================================
    
    access(all) let DAY_START_HOUR: Int    // 6 AM
    access(all) let NIGHT_START_HOUR: Int  // 6 PM
    
    // ========================================
    // EVENTS
    // ========================================
    
    access(all) event ParadiseMotelInitialized()
    access(all) event DayNightCycleChecked(owner: Address, isDaytime: Bool, localHour: Int, timezone: Int)
    access(all) event ImageSwitched(owner: Address, from: String, to: String, context: String)
    
    // ========================================
    // DYNAMIC METADATA RESOLVER
    // ========================================
    
    /// Resolves the correct image URI based on user's local time
    /// Returns day image (6 AM - 6 PM) or night image (6 PM - 6 AM)
    access(all) fun resolveParadiseMotelImage(
        ownerAddress: Address,
        dayImageURI: String,
        nightImageURI: String
    ): String {
        // Get owner's profile
        let account = getAccount(ownerAddress)
        let profileRef = account.capabilities
            .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        // If no profile, return day image as default
        if profileRef == nil {
            return dayImageURI
        }
        
        let profile = profileRef!
        let isDaytime = profile.isDaytime()
        let localHour = profile.getLocalHour()
        
        emit DayNightCycleChecked(
            owner: ownerAddress,
            isDaytime: isDaytime,
            localHour: localHour,
            timezone: profile.timezone
        )
        
        // Return appropriate image
        let selectedImage = isDaytime ? dayImageURI : nightImageURI
        let context = isDaytime ? "day" : "night"
        
        emit ImageSwitched(
            owner: ownerAddress,
            from: isDaytime ? nightImageURI : dayImageURI,
            to: selectedImage,
            context: context
        )
        
        return selectedImage
    }
    
    // ========================================
    // PARADISE MOTEL DISPLAY STRUCT
    // ========================================
    
    /// Enhanced display struct with dynamic day/night support
    access(all) struct ParadiseMotelDisplay {
        access(all) let nftID: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let owner: Address
        
        // Static URIs (stored in metadata)
        access(all) let dayImageURI: String
        access(all) let nightImageURI: String
        
        // Dynamic resolution
        access(all) let currentImageURI: String  // Resolved based on time
        access(all) let timeContext: String      // "day" or "night"
        access(all) let ownerLocalHour: Int
        access(all) let ownerTimezone: Int
        access(all) let isDaytime: Bool
        
        // Additional metadata
        access(all) let motelLevel: String       // "Paradise Motel"
        access(all) let roomNumber: Int?
        access(all) let specialFeatures: [String]
        
        init(
            nftID: UInt64,
            name: String,
            description: String,
            owner: Address,
            dayImageURI: String,
            nightImageURI: String,
            motelLevel: String,
            roomNumber: Int?,
            specialFeatures: [String]
        ) {
            self.nftID = nftID
            self.name = name
            self.description = description
            self.owner = owner
            self.dayImageURI = dayImageURI
            self.nightImageURI = nightImageURI
            self.motelLevel = motelLevel
            self.roomNumber = roomNumber
            self.specialFeatures = specialFeatures
            
            // Resolve dynamic fields
            let account = getAccount(owner)
            let profileRef = account.capabilities
                .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
                .borrow()
            
            if let profile = profileRef {
                self.isDaytime = profile.isDaytime()
                self.ownerLocalHour = profile.getLocalHour()
                self.ownerTimezone = profile.timezone
                self.timeContext = self.isDaytime ? "day" : "night"
                self.currentImageURI = self.isDaytime ? dayImageURI : nightImageURI
            } else {
                // Defaults if no profile
                self.isDaytime = true
                self.ownerLocalHour = 12
                self.ownerTimezone = 0
                self.timeContext = "day"
                self.currentImageURI = dayImageURI
            }
        }
    }
    
    // ========================================
    // METADATA VIEWS INTEGRATION (OPTIONAL)
    // ========================================
    
    // Uncomment if you need MetadataViews.Display integration
    // Requires: import MetadataViews from "./MetadataViews.cdc"
    /*
    /// Creates a MetadataViews.Display with dynamic image resolution
    access(all) fun createDynamicDisplay(
        name: String,
        description: String,
        owner: Address,
        dayImageURI: String,
        nightImageURI: String
    ): MetadataViews.Display {
        let resolvedImage = resolveParadiseMotelImage(
            ownerAddress: owner,
            dayImageURI: dayImageURI,
            nightImageURI: nightImageURI
        )
        
        return MetadataViews.Display(
            name: name,
            description: description,
            thumbnail: MetadataViews.HTTPFile(url: resolvedImage)
        )
    }
    */
    
    // ========================================
    // SUPABASE SYNC HELPERS
    // ========================================
    
    /// Get current image URI for Supabase sync
    /// This is called from your website to determine which image to show
    access(all) fun getCurrentImageForSupabase(
        ownerAddress: Address,
        dayImageURI: String,
        nightImageURI: String
    ): {String: AnyStruct} {
        let account = getAccount(ownerAddress)
        let profileRef = account.capabilities
            .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        if profileRef == nil {
            return {
                "imageURI": dayImageURI,
                "timeContext": "day",
                "isDaytime": true,
                "localHour": 12,
                "timezone": 0,
                "hasProfile": false
            }
        }
        
        let profile = profileRef!
        let isDaytime = profile.isDaytime()
        
        return {
            "imageURI": isDaytime ? dayImageURI : nightImageURI,
            "timeContext": isDaytime ? "day" : "night",
            "isDaytime": isDaytime,
            "localHour": profile.getLocalHour(),
            "timezone": profile.timezone,
            "hasProfile": true
        }
    }
    
    // ========================================
    // BATCH OPERATIONS
    // ========================================
    
    /// Get day/night status for multiple users
    /// Useful for batch rendering on website
    access(all) fun batchGetTimeContext(addresses: [Address]): [{String: AnyStruct}] {
        let results: [{String: AnyStruct}] = []
        
        for address in addresses {
            let account = getAccount(address)
            let profileRef = account.capabilities
                .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
                .borrow()
            
            if let profile = profileRef {
                results.append({
                    "address": address.toString(),
                    "isDaytime": profile.isDaytime(),
                    "localHour": profile.getLocalHour(),
                    "timezone": profile.timezone,
                    "timeContext": profile.isDaytime() ? "day" : "night"
                })
            } else {
                results.append({
                    "address": address.toString(),
                    "isDaytime": true,
                    "localHour": 12,
                    "timezone": 0,
                    "timeContext": "day",
                    "hasProfile": false
                })
            }
        }
        
        return results
    }
    
    // ========================================
    // TIME UTILITIES
    // ========================================
    
    /// Check if it's currently day or night for a specific timezone
    access(all) fun isDaytimeForTimezone(timezone: Int): Bool {
        let timestamp = getCurrentBlock().timestamp
        let utcHour = Int((timestamp / 3600.0) % 24.0)
        var localHour = utcHour + timezone
        
        // Wrap around for valid hours (0-23)
        if localHour < 0 {
            localHour = localHour + 24
        } else if localHour >= 24 {
            localHour = localHour - 24
        }
        
        // Daytime: 6 AM (6) to 6 PM (18)
        return localHour >= ParadiseMotel.DAY_START_HOUR && localHour < ParadiseMotel.NIGHT_START_HOUR
    }
    
    /// Get the local hour for a specific timezone
    access(all) fun getLocalHourForTimezone(timezone: Int): Int {
        let timestamp = getCurrentBlock().timestamp
        let utcHour = Int((timestamp / 3600.0) % 24.0)
        var localHour = utcHour + timezone
        
        if localHour < 0 {
            localHour = localHour + 24
        } else if localHour >= 24 {
            localHour = localHour - 24
        }
        
        return localHour
    }
    
    init() {
        self.DAY_START_HOUR = 6    // 6 AM
        self.NIGHT_START_HOUR = 18 // 6 PM
        
        emit ParadiseMotelInitialized()
    }
}
