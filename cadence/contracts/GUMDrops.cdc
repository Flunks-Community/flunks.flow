// GUMDrops - Flow Actions-based airdrop system for GUM tokens
// Complements existing Staking rewards with check-in bonuses and time-based drops

import FungibleToken from "./FungibleToken.cdc"
import GUM from "./GUM.cdc"
import Flunks from "./Flunks.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"

access(all)
contract GUMDrops {
    
    // Storage Paths
    access(all) let AdminStoragePath: StoragePath
    access(all) let ClaimTrackerStoragePath: StoragePath
    access(all) let ClaimTrackerPublicPath: PublicPath

    // Events
    access(all) event CheckInClaimed(address: Address, amount: UFix64, timestamp: UFix64, streak: UInt64)
    access(all) event TimeBonusClaimed(address: Address, amount: UFix64, timeOfDay: String)
    access(all) event FlunksHolderBonusClaimed(address: Address, amount: UFix64, flunksCount: UInt64)
    access(all) event DropScheduleCreated(dropID: UInt64, totalAmount: UFix64, startTime: UFix64)
    access(all) event DropClaimed(dropID: UInt64, address: Address, amount: UFix64)

    // Constants
    access(all) let SECONDS_PER_DAY: UFix64
    access(all) let BASE_CHECKIN_REWARD: UFix64
    access(all) let STREAK_BONUS_MULTIPLIER: UFix64
    access(all) let AM_BONUS: UFix64  // 6am - 12pm
    access(all) let PM_BONUS: UFix64  // 6pm - 12am
    access(all) let FLUNKS_HOLDER_BONUS: UFix64  // Per Flunks owned

    // Tracking
    access(self) var nextDropID: UInt64
    access(self) var scheduledDrops: @{UInt64: ScheduledDrop}

    // User claim tracking struct
    access(all) struct UserClaimData {
        access(all) var lastCheckInTime: UFix64
        access(all) var currentStreak: UInt64
        access(all) var totalCheckIns: UInt64
        access(all) var lastAMClaim: UFix64
        access(all) var lastPMClaim: UFix64
        access(all) var claimedDrops: {UInt64: Bool}
        access(all) var totalGUMClaimed: UFix64

        init() {
            self.lastCheckInTime = 0.0
            self.currentStreak = 0
            self.totalCheckIns = 0
            self.lastAMClaim = 0.0
            self.lastPMClaim = 0.0
            self.claimedDrops = {}
            self.totalGUMClaimed = 0.0
        }

        access(all) fun updateCheckIn(timestamp: UFix64) {
            let daysSinceLastCheckIn = (timestamp - self.lastCheckInTime) / GUMDrops.SECONDS_PER_DAY
            
            if daysSinceLastCheckIn < 1.0 {
                // Same day, no update
                return
            } else if daysSinceLastCheckIn < 2.0 {
                // Next day, increment streak
                self.currentStreak = self.currentStreak + 1
            } else {
                // Streak broken, reset to 1
                self.currentStreak = 1
            }
            
            self.lastCheckInTime = timestamp
            self.totalCheckIns = self.totalCheckIns + 1
        }

        access(all) fun recordAMClaim(timestamp: UFix64) {
            self.lastAMClaim = timestamp
        }

        access(all) fun recordPMClaim(timestamp: UFix64) {
            self.lastPMClaim = timestamp
        }

        access(all) fun recordDropClaim(dropID: UInt64) {
            self.claimedDrops[dropID] = true
        }

        access(all) fun addClaimedAmount(amount: UFix64) {
            self.totalGUMClaimed = self.totalGUMClaimed + amount
        }
    }

    // Public interface for claim tracker
    access(all) resource interface ClaimTrackerPublic {
        access(all) fun getUserData(address: Address): UserClaimData?
        access(all) fun canClaimCheckIn(address: Address): Bool
        access(all) fun canClaimAMBonus(address: Address): Bool
        access(all) fun canClaimPMBonus(address: Address): Bool
        access(all) fun getStreak(address: Address): UInt64
    }

    // Claim tracking resource
    access(all) resource ClaimTracker: ClaimTrackerPublic {
        access(self) var userData: {Address: UserClaimData}

        init() {
            self.userData = {}
        }

        access(all) fun getUserData(address: Address): UserClaimData? {
            return self.userData[address]
        }

        access(all) fun getOrCreateUserData(address: Address): UserClaimData {
            if self.userData[address] == nil {
                self.userData[address] = UserClaimData()
            }
            return self.userData[address]!
        }

        access(all) fun canClaimCheckIn(address: Address): Bool {
            let userData = self.userData[address] ?? UserClaimData()
            let currentTime = getCurrentBlock().timestamp
            let timeSinceLastCheckIn = currentTime - userData.lastCheckInTime
            
            return timeSinceLastCheckIn >= GUMDrops.SECONDS_PER_DAY
        }

        access(all) fun canClaimAMBonus(address: Address): Bool {
            let userData = self.userData[address] ?? UserClaimData()
            let currentTime = getCurrentBlock().timestamp
            let timeSinceLastAM = currentTime - userData.lastAMClaim
            
            // Can claim once per day AND must be AM hours
            return timeSinceLastAM >= GUMDrops.SECONDS_PER_DAY && GUMDrops.isAMHours()
        }

        access(all) fun canClaimPMBonus(address: Address): Bool {
            let userData = self.userData[address] ?? UserClaimData()
            let currentTime = getCurrentBlock().timestamp
            let timeSinceLastPM = currentTime - userData.lastPMClaim
            
            // Can claim once per day AND must be PM hours
            return timeSinceLastPM >= GUMDrops.SECONDS_PER_DAY && GUMDrops.isPMHours()
        }

        access(all) fun getStreak(address: Address): UInt64 {
            let userData = self.userData[address] ?? UserClaimData()
            return userData.currentStreak
        }

        access(contract) fun updateCheckIn(address: Address, timestamp: UFix64) {
            var userData = self.getOrCreateUserData(address: address)
            userData.updateCheckIn(timestamp: timestamp)
            self.userData[address] = userData
        }

        access(contract) fun recordAMClaim(address: Address, timestamp: UFix64) {
            var userData = self.getOrCreateUserData(address: address)
            userData.recordAMClaim(timestamp: timestamp)
            self.userData[address] = userData
        }

        access(contract) fun recordPMClaim(address: Address, timestamp: UFix64) {
            var userData = self.getOrCreateUserData(address: address)
            userData.recordPMClaim(timestamp: timestamp)
            self.userData[address] = userData
        }

        access(contract) fun recordDropClaim(address: Address, dropID: UInt64) {
            var userData = self.getOrCreateUserData(address: address)
            userData.recordDropClaim(dropID: dropID)
            self.userData[address] = userData
        }

        access(contract) fun addClaimedAmount(address: Address, amount: UFix64) {
            var userData = self.getOrCreateUserData(address: address)
            userData.addClaimedAmount(amount: amount)
            self.userData[address] = userData
        }
    }

    // Scheduled drop resource
    access(all) resource ScheduledDrop {
        access(all) let dropID: UInt64
        access(all) let totalAmount: UFix64
        access(all) let amountPerClaim: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64?
        access(all) let requiresFlunks: Bool
        access(all) var remainingAmount: UFix64
        access(self) var claimedAddresses: {Address: Bool}

        init(
            dropID: UInt64,
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64?,
            requiresFlunks: Bool
        ) {
            self.dropID = dropID
            self.totalAmount = totalAmount
            self.amountPerClaim = amountPerClaim
            self.startTime = startTime
            self.endTime = endTime
            self.requiresFlunks = requiresFlunks
            self.remainingAmount = totalAmount
            self.claimedAddresses = {}
        }

        access(all) fun canClaim(address: Address): Bool {
            let currentTime = getCurrentBlock().timestamp
            
            // Check if drop is active
            if currentTime < self.startTime {
                return false
            }
            
            if self.endTime != nil && currentTime > self.endTime! {
                return false
            }
            
            // Check if already claimed
            if self.claimedAddresses[address] == true {
                return false
            }
            
            // Check if enough remaining
            if self.remainingAmount < self.amountPerClaim {
                return false
            }
            
            return true
        }

        access(contract) fun recordClaim(address: Address): UFix64 {
            pre {
                self.canClaim(address: address): "Cannot claim from this drop"
            }
            
            self.claimedAddresses[address] = true
            self.remainingAmount = self.remainingAmount - self.amountPerClaim
            
            return self.amountPerClaim
        }
    }

    // Admin resource
    access(all) resource Admin {
        
        // Create a scheduled drop
        access(all) fun createScheduledDrop(
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64?,
            requiresFlunks: Bool
        ): UInt64 {
            let dropID = GUMDrops.nextDropID
            let drop <- create ScheduledDrop(
                dropID: dropID,
                totalAmount: totalAmount,
                amountPerClaim: amountPerClaim,
                startTime: startTime,
                endTime: endTime,
                requiresFlunks: requiresFlunks
            )
            
            GUMDrops.scheduledDrops[dropID] <-! drop
            GUMDrops.nextDropID = GUMDrops.nextDropID + 1
            
            emit DropScheduleCreated(dropID: dropID, totalAmount: totalAmount, startTime: startTime)
            
            return dropID
        }

        // Remove a scheduled drop
        access(all) fun removeScheduledDrop(dropID: UInt64) {
            destroy GUMDrops.scheduledDrops.remove(key: dropID)
        }
    }

    // Helper functions
    access(all) fun isAMHours(): Bool {
        // This is a simplified version - in production you'd want timezone awareness
        // For now, using block timestamp modulo to determine "morning" (6am-12pm UTC)
        let timestamp = getCurrentBlock().timestamp
        let secondsInDay: UFix64 = 86400.0
        let secondsInHour: UFix64 = 3600.0
        let hourOfDay = (timestamp % secondsInDay) / secondsInHour  // Get hour of day (0-23)
        return hourOfDay >= 6.0 && hourOfDay < 12.0
    }

    access(all) fun isPMHours(): Bool {
        // Evening hours (6pm-12am UTC)
        let timestamp = getCurrentBlock().timestamp
        let secondsInDay: UFix64 = 86400.0
        let secondsInHour: UFix64 = 3600.0
        let hourOfDay = (timestamp % secondsInDay) / secondsInHour
        return hourOfDay >= 18.0 && hourOfDay < 24.0
    }

    access(all) fun getFlunksCount(address: Address): UInt64 {
        let account = getAccount(address)
        let collectionRef = account.capabilities
            .get<&{Flunks.FlunksCollectionPublic}>(Flunks.CollectionPublicPath)
            .borrow()
        
        if collectionRef == nil {
            return 0
        }
        
        return UInt64(collectionRef!.getIDs().length)
    }

    // Public claiming functions
    access(all) fun claimDailyCheckIn(claimer: auth(Storage, Capabilities) &Account) {
        let tracker = self.account.storage.borrow<&ClaimTracker>(from: self.ClaimTrackerStoragePath)
            ?? panic("Could not borrow ClaimTracker")
        
        // Verify can claim
        assert(tracker.canClaimCheckIn(address: claimer.address), message: "Cannot claim check-in yet")
        
        // Calculate reward based on streak
        let currentTime = getCurrentBlock().timestamp
        tracker.updateCheckIn(address: claimer.address, timestamp: currentTime)
        
        let streak = tracker.getStreak(address: claimer.address)
        let streakBonus = UFix64(streak) * self.STREAK_BONUS_MULTIPLIER
        let totalReward = self.BASE_CHECKIN_REWARD + streakBonus
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: totalReward)
        
        // Update tracker
        tracker.addClaimedAmount(address: claimer.address, amount: totalReward)
        
        emit CheckInClaimed(address: claimer.address, amount: totalReward, timestamp: currentTime, streak: streak)
    }

    access(all) fun claimAMBonus(claimer: auth(Storage, Capabilities) &Account) {
        let tracker = self.account.storage.borrow<&ClaimTracker>(from: self.ClaimTrackerStoragePath)
            ?? panic("Could not borrow ClaimTracker")
        
        assert(tracker.canClaimAMBonus(address: claimer.address), message: "Cannot claim AM bonus")
        
        let currentTime = getCurrentBlock().timestamp
        tracker.recordAMClaim(address: claimer.address, timestamp: currentTime)
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: self.AM_BONUS)
        
        tracker.addClaimedAmount(address: claimer.address, amount: self.AM_BONUS)
        
        emit TimeBonusClaimed(address: claimer.address, amount: self.AM_BONUS, timeOfDay: "AM")
    }

    access(all) fun claimPMBonus(claimer: auth(Storage, Capabilities) &Account) {
        let tracker = self.account.storage.borrow<&ClaimTracker>(from: self.ClaimTrackerStoragePath)
            ?? panic("Could not borrow ClaimTracker")
        
        assert(tracker.canClaimPMBonus(address: claimer.address), message: "Cannot claim PM bonus")
        
        let currentTime = getCurrentBlock().timestamp
        tracker.recordPMClaim(address: claimer.address, timestamp: currentTime)
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: self.PM_BONUS)
        
        tracker.addClaimedAmount(address: claimer.address, amount: self.PM_BONUS)
        
        emit TimeBonusClaimed(address: claimer.address, amount: self.PM_BONUS, timeOfDay: "PM")
    }

    access(all) fun claimFlunksHolderBonus(claimer: auth(Storage, Capabilities) &Account) {
        let flunksCount = self.getFlunksCount(address: claimer.address)
        
        assert(flunksCount > 0, message: "Must own at least one Flunks NFT")
        
        let bonusAmount = UFix64(flunksCount) * self.FLUNKS_HOLDER_BONUS
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: bonusAmount)
        
        let tracker = self.account.storage.borrow<&ClaimTracker>(from: self.ClaimTrackerStoragePath)
            ?? panic("Could not borrow ClaimTracker")
        
        tracker.addClaimedAmount(address: claimer.address, amount: bonusAmount)
        
        emit FlunksHolderBonusClaimed(address: claimer.address, amount: bonusAmount, flunksCount: flunksCount)
    }

    access(all) fun claimScheduledDrop(claimer: auth(Storage, Capabilities) &Account, dropID: UInt64) {
        let dropRef = &self.scheduledDrops[dropID] as &ScheduledDrop?
            ?? panic("Drop not found")
        
        // Check if requires Flunks ownership
        if dropRef.requiresFlunks {
            let flunksCount = self.getFlunksCount(address: claimer.address)
            assert(flunksCount > 0, message: "Must own Flunks NFT to claim this drop")
        }
        
        let claimAmount = dropRef.recordClaim(address: claimer.address)
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: claimAmount)
        
        let tracker = self.account.storage.borrow<&ClaimTracker>(from: self.ClaimTrackerStoragePath)
            ?? panic("Could not borrow ClaimTracker")
        
        tracker.recordDropClaim(address: claimer.address, dropID: dropID)
        tracker.addClaimedAmount(address: claimer.address, amount: claimAmount)
        
        emit DropClaimed(dropID: dropID, address: claimer.address, amount: claimAmount)
    }

    // Internal helper to mint GUM to user
    access(self) fun mintToUser(address: Address, amount: UFix64) {
        let minter = self.account.storage.borrow<&GUM.Minter>(from: GUM.AdminStoragePath)
            ?? panic("Could not borrow GUM Minter")
        
        let vault <- minter.mintTokens(amount: amount)
        
        let recipientVault = getAccount(address).capabilities
            .get<&{FungibleToken.Receiver}>(GUM.VaultReceiverPublicPath)
            .borrow()
            ?? panic("Could not borrow recipient vault")
        
        recipientVault.deposit(from: <- vault)
    }

    // Public view functions
    access(all) fun getScheduledDrop(dropID: UInt64): &ScheduledDrop? {
        return &self.scheduledDrops[dropID] as &ScheduledDrop?
    }

    access(all) fun createEmptyClaimTracker(): @ClaimTracker {
        return <- create ClaimTracker()
    }

    init() {
        // Set paths
        self.AdminStoragePath = /storage/GUMDropsAdmin
        self.ClaimTrackerStoragePath = /storage/GUMDropsClaimTracker
        self.ClaimTrackerPublicPath = /public/GUMDropsClaimTracker

        // Set constants
        self.SECONDS_PER_DAY = 86400.0
        self.BASE_CHECKIN_REWARD = 10.0  // 10 GUM base reward
        self.STREAK_BONUS_MULTIPLIER = 1.0  // +1 GUM per day streak
        self.AM_BONUS = 5.0  // 5 GUM for AM check-in
        self.PM_BONUS = 5.0  // 5 GUM for PM check-in
        self.FLUNKS_HOLDER_BONUS = 2.0  // 2 GUM per Flunks owned

        // Initialize tracking
        self.nextDropID = 0
        self.scheduledDrops <- {}

        // Create and save admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        // Create and save claim tracker
        let tracker <- create ClaimTracker()
        self.account.storage.save(<-tracker, to: self.ClaimTrackerStoragePath)

        // Publish claim tracker capability
        let trackerCap = self.account.capabilities.storage.issue<&ClaimTracker>(self.ClaimTrackerStoragePath)
        self.account.capabilities.publish(trackerCap, at: self.ClaimTrackerPublicPath)
    }
}
