// FlunksGumDrop.cdc
// Production-ready GumDrop contract for special events
// This contract allows Flunk NFT holders to claim special GUM rewards during limited-time events

access(all) contract FlunksGumDrop {
    
    // Event emitted when a user claims their GumDrop
    access(all) event GumDropClaimed(user: Address, amount: UInt64, timestamp: UFix64)
    
    // Event emitted when the drop window changes
    access(all) event DropWindowUpdated(startTime: UFix64, endTime: UFix64, isActive: Bool)
    
    // Storage paths
    access(all) let AdminStoragePath: StoragePath
    
    // Contract state
    access(all) var dropStartTime: UFix64
    access(all) var dropEndTime: UFix64
    access(all) var gumAmountPerFlunk: UInt64
    access(all) var dropActive: Bool
    
    // Track who has claimed (address -> claimed timestamp)
    access(self) let claimRecord: {Address: UFix64}
    
    // Admin resource for managing drops
    access(all) resource Admin {
        // Start a new GumDrop event
        access(all) fun startDrop(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64) {
            pre {
                endTime > startTime: "End time must be after start time"
                gumPerFlunk > 0: "GUM amount must be positive"
            }
            
            FlunksGumDrop.dropStartTime = startTime
            FlunksGumDrop.dropEndTime = endTime
            FlunksGumDrop.gumAmountPerFlunk = gumPerFlunk
            FlunksGumDrop.dropActive = true
            
            emit DropWindowUpdated(startTime: startTime, endTime: endTime, isActive: true)
        }
        
        // End the current drop
        access(all) fun endDrop() {
            FlunksGumDrop.dropActive = false
            emit DropWindowUpdated(startTime: 0.0, endTime: 0.0, isActive: false)
        }
        
        // Reset a user's claim (emergency only)
        access(all) fun resetUserClaim(user: Address) {
            let removed = FlunksGumDrop.claimRecord.remove(key: user)
        }
    }
    
    // Check if drop is currently active
    access(all) view fun checkDropActive(): Bool {
        let now = getCurrentBlock().timestamp
        return self.dropActive && 
               now >= self.dropStartTime && 
               now <= self.dropEndTime
    }
    
    // Get remaining time in seconds
    access(all) view fun getTimeRemaining(): UFix64 {
        if !self.checkDropActive() {
            return 0.0
        }
        let now = getCurrentBlock().timestamp
        if now >= self.dropEndTime {
            return 0.0
        }
        return self.dropEndTime - now
    }
    
    // Check if user is eligible to claim
    access(all) view fun isEligibleForGumDrop(user: Address): Bool {
        // User is eligible if:
        // 1. Drop is active
        // 2. They haven't claimed yet
        // 3. They own at least one Flunk NFT (checked in frontend/API)
        return self.checkDropActive() && 
               self.claimRecord[user] == nil
    }
    
    // Get drop info
    access(all) view fun getGumDropInfo(): {String: AnyStruct} {
        let now = getCurrentBlock().timestamp
        let active = self.checkDropActive()
        
        return {
            "isActive": active,
            "startTime": self.dropStartTime,
            "endTime": self.dropEndTime,
            "timeRemaining": active ? self.getTimeRemaining() : 0.0,
            "gumPerFlunk": self.gumAmountPerFlunk,
            "currentTime": now
        }
    }
    
    // Claim GumDrop - records on-chain that user claimed
    access(all) fun claimGumDrop(user: Address) {
        pre {
            self.checkDropActive(): "No active GumDrop event"
            self.claimRecord[user] == nil: "Already claimed this drop"
        }
        
        // Record the claim
        let now = getCurrentBlock().timestamp
        self.claimRecord[user] = now
        
        // Emit event (actual GUM crediting happens via Supabase API)
        emit GumDropClaimed(user: user, amount: self.gumAmountPerFlunk, timestamp: now)
    }
    
    // Get user's claim status
    access(all) view fun getUserClaimTime(user: Address): UFix64? {
        return self.claimRecord[user]
    }
    
    init() {
        // Set storage paths
        self.AdminStoragePath = /storage/FlunksGumDropAdmin
        
        // Initialize with no active drop
        self.dropStartTime = 0.0
        self.dropEndTime = 0.0
        self.gumAmountPerFlunk = 100
        self.dropActive = false
        self.claimRecord = {}
        
        // Create and store admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
    }
}
