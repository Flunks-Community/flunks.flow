import SemesterZero from 0x807c3d470888cc48

/// Simple handler for starting the GumDrop - no scheduler needed!
/// Anyone can trigger this once the start time is reached
access(all) contract SimpleDropHandler {
    
    /// Storage path for the handler resource
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    
    /// Public interface for the handler
    access(all) resource interface HandlerPublic {
        access(all) fun canTrigger(): Bool
        access(all) fun getScheduledStart(): UFix64
        access(all) fun triggerDrop()
    }
    
    /// Handler resource that anyone can create and use to start the drop
    access(all) resource Handler: HandlerPublic {
        access(all) let scheduledStartTime: UFix64
        access(all) let scheduledEndTime: UFix64
        access(all) let gumPerFlunk: UInt64
        access(all) var hasTriggered: Bool
        
        /// Check if the drop can be triggered
        access(all) fun canTrigger(): Bool {
            return !self.hasTriggered && getCurrentBlock().timestamp >= self.scheduledStartTime
        }
        
        access(all) fun getScheduledStart(): UFix64 {
            return self.scheduledStartTime
        }
        
        /// Anyone can call this to start the drop once the time is reached
        access(all) fun triggerDrop() {
            pre {
                !self.hasTriggered: "Drop has already been triggered"
                getCurrentBlock().timestamp >= self.scheduledStartTime: "Too early to start the drop"
            }
            
            // Get admin reference from the contract account
            let adminRef = SimpleDropHandler.account.storage
                .borrow<&SemesterZero.Admin>(from: SemesterZero.AdminStoragePath)
                ?? panic("Could not borrow Admin reference")
            
            // Start the Halloween drop
            adminRef.startDrop(
                startTime: self.scheduledStartTime,
                endTime: self.scheduledEndTime,
                gumPerFlunk: self.gumPerFlunk
            )
            
            self.hasTriggered = true
            
            emit DropTriggered(
                startTime: self.scheduledStartTime,
                endTime: self.scheduledEndTime,
                triggeredAt: getCurrentBlock().timestamp
            )
            
            log("🎃 Halloween GumDrop activated!")
        }
        
        init(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64) {
            self.scheduledStartTime = startTime
            self.scheduledEndTime = endTime
            self.gumPerFlunk = gumPerFlunk
            self.hasTriggered = false
        }
    }
    
    /// Event emitted when drop is triggered
    access(all) event DropTriggered(startTime: UFix64, endTime: UFix64, triggeredAt: UFix64)
    
    /// Create a new handler (admin only via transaction)
    access(all) fun createHandler(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64): @Handler {
        return <- create Handler(
            startTime: startTime,
            endTime: endTime,
            gumPerFlunk: gumPerFlunk
        )
    }
    
    init() {
        self.HandlerStoragePath = /storage/SimpleDropHandler
        self.HandlerPublicPath = /public/SimpleDropHandler
    }
}
