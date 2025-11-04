import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

/// TestPumpkinDrop420 - Forte Hackathon Edition
/// 3 Blockchain Features:
/// 1. GumDrop Airdrop (72-hour claim window) - Flow Actions triggers create/close
/// 2. Paradise Motel Day/Night (per-user timezone) - Personalized 12hr cycle using blockchain storage
/// 3. Chapter 5 NFT Airdrop (100% completion) - Auto-airdrop on slacker + overachiever complete
///
/// For flunks.flow deployment - October 2025
access(all) contract TestPumpkinDrop420 {
    
    // ========================================
    // PATHS
    // ========================================
    
    access(all) let UserProfileStoragePath: StoragePath
    access(all) let UserProfilePublicPath: PublicPath
    access(all) let Chapter5CollectionStoragePath: StoragePath
    access(all) let Chapter5CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // ========================================
    // EVENTS
    // ========================================
    
    // Contract lifecycle
    access(all) event ContractInitialized()
    
    // GumDrop Events (72-hour claim window)
    access(all) event GumDropCreated(dropId: String, eligibleCount: Int, amount: UFix64, startTime: UFix64, endTime: UFix64)
    access(all) event GumDropClaimed(user: Address, dropId: String, amount: UFix64, timestamp: UFix64)
    access(all) event GumDropClosed(dropId: String, totalClaimed: Int, totalEligible: Int)
    
    // Chapter 5 Events
    access(all) event Chapter5SlackerCompleted(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5OverachieverCompleted(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5FullCompletion(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5NFTMinted(nftID: UInt64, recipient: Address, timestamp: UFix64)
    
    // ========================================
    // STATE VARIABLES
    // ========================================
    
    // GumDrop system
    access(all) var activeGumDrop: GumDrop?
    access(all) var totalGumDrops: UInt64
    
    // Chapter 5 tracking
    access(all) var totalChapter5Completions: UInt64
    access(all) var totalChapter5NFTs: UInt64
    access(all) let chapter5Completions: {Address: Chapter5Status}
    
    // ========================================
    // STRUCTS
    // ========================================
    
    /// GumDrop - 72-hour claim window for airdrop eligibility
    /// Flow Actions creates drop → Website shows button → User claims → Backend adds GUM to Supabase
    /// Flow Actions closes drop after 72hrs → Website hides button
    access(all) struct GumDrop {
        access(all) let dropId: String
        access(all) let amount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let eligibleUsers: {Address: Bool}
        access(all) var claimedUsers: {Address: UFix64}
        
        init(dropId: String, amount: UFix64, eligibleUsers: [Address], durationSeconds: UFix64) {
            self.dropId = dropId
            self.amount = amount
            self.startTime = getCurrentBlock().timestamp
            self.endTime = self.startTime + durationSeconds
            self.eligibleUsers = {}
            self.claimedUsers = {}
            
            for addr in eligibleUsers {
                self.eligibleUsers[addr] = true
            }
        }
        
        access(all) fun isEligible(user: Address): Bool {
            return self.eligibleUsers[user] == true && self.claimedUsers[user] == nil
        }
        
        access(all) fun hasClaimed(user: Address): Bool {
            return self.claimedUsers[user] != nil
        }
        
        access(all) fun isActive(): Bool {
            let now = getCurrentBlock().timestamp
            return now >= self.startTime && now <= self.endTime
        }
        
        access(all) fun markClaimed(user: Address) {
            assert(self.eligibleUsers[user] == true, message: "User not eligible for this drop")
            assert(self.claimedUsers[user] == nil, message: "User already claimed")
            assert(self.isActive(), message: "Drop window has expired")
            
            self.claimedUsers[user] = getCurrentBlock().timestamp
        }
        
        access(all) fun getTimeRemaining(): UFix64 {
            let now = getCurrentBlock().timestamp
            if now >= self.endTime {
                return 0.0
            }
            return self.endTime - now
        }
    }
    
    /// Chapter 5 Status - Tracks slacker + overachiever completion
    access(all) struct Chapter5Status {
        access(all) let userAddress: Address
        access(all) var slackerComplete: Bool
        access(all) var overachieverComplete: Bool
        access(all) var nftAirdropped: Bool
        access(all) var nftID: UInt64?
        access(all) var slackerTimestamp: UFix64
        access(all) var overachieverTimestamp: UFix64
        access(all) var completionTimestamp: UFix64
        
        init(userAddress: Address) {
            self.userAddress = userAddress
            self.slackerComplete = false
            self.overachieverComplete = false
            self.nftAirdropped = false
            self.nftID = nil
            self.slackerTimestamp = 0.0
            self.overachieverTimestamp = 0.0
            self.completionTimestamp = 0.0
        }
        
        access(all) fun markSlackerComplete() {
            self.slackerComplete = true
            self.slackerTimestamp = getCurrentBlock().timestamp
            self.checkFullCompletion()
        }
        
        access(all) fun markOverachieverComplete() {
            self.overachieverComplete = true
            self.overachieverTimestamp = getCurrentBlock().timestamp
            self.checkFullCompletion()
        }
        
        access(all) fun checkFullCompletion() {
            if self.slackerComplete && self.overachieverComplete && self.completionTimestamp == 0.0 {
                self.completionTimestamp = getCurrentBlock().timestamp
            }
        }
        
        access(all) fun isFullyComplete(): Bool {
            return self.slackerComplete && self.overachieverComplete
        }
        
        access(all) fun markNFTAirdropped(nftID: UInt64) {
            self.nftAirdropped = true
            self.nftID = nftID
        }
    }
    
    // ========================================
    // USER PROFILE
    // ========================================
    
    /// UserProfile - Stores user's timezone for Paradise Motel day/night personalization
    /// Created during first GumDrop claim (combo transaction)
    access(all) resource UserProfile {
        access(all) var username: String
        access(all) var timezone: Int  // UTC offset in hours (e.g., -7 for PDT, -5 for EST)
        
        init(username: String, timezone: Int) {
            self.username = username
            self.timezone = timezone
        }
    }
    
    // ========================================
    // CHAPTER 5 NFT
    // ========================================
    
    access(all) resource Chapter5NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let achievementType: String
        access(all) let recipient: Address
        access(all) let mintedAt: UFix64
        access(all) let metadata: {String: String}
        
        init(id: UInt64, recipient: Address) {
            self.id = id
            self.achievementType = "SLACKER_AND_OVERACHIEVER"
            self.recipient = recipient
            self.mintedAt = getCurrentBlock().timestamp
            self.metadata = {
                "name": "Chapter 5 Completion",
                "description": "Awarded for completing both Slacker and Overachiever objectives in Chapter 5",
                "achievement": "SLACKER_AND_OVERACHIEVER",
                "chapter": "5",
                "rarity": "Legendary",
                "image": "https://storage.googleapis.com/flunks_public/nfts/chapter5-completion.png"
            }
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<MetadataViews.Display>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"]!,
                        description: self.metadata["description"]!,
                        thumbnail: MetadataViews.HTTPFile(url: self.metadata["image"]!)
                    )
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-TestPumpkinDrop420.createEmptyChapter5Collection()
        }
    }
    
    // ========================================
    // CHAPTER 5 COLLECTION
    // ========================================
    
    access(all) resource Chapter5Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("NFT not found in collection")
            return <-token
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @TestPumpkinDrop420.Chapter5NFT
            let id = nft.id
            let oldToken <- self.ownedNFTs[id] <- nft
            destroy oldToken
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@TestPumpkinDrop420.Chapter5NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@TestPumpkinDrop420.Chapter5NFT>()
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-TestPumpkinDrop420.createEmptyChapter5Collection()
        }
    }
    
    // ========================================
    // ADMIN RESOURCE
    // ========================================
    
    access(all) resource Admin {
        
        // === GUM DROP MANAGEMENT ===
        
        /// Create a new GumDrop with 72-hour claim window (called by Flow Actions)
        access(all) fun createGumDrop(
            dropId: String,
            eligibleAddresses: [Address],
            amount: UFix64,
            durationSeconds: UFix64
        ) {
            pre {
                TestPumpkinDrop420.activeGumDrop == nil: "Active GumDrop already exists. Close it first."
                eligibleAddresses.length > 0: "Must have at least one eligible user"
                amount > 0.0: "Amount must be greater than 0"
                durationSeconds > 0.0: "Duration must be greater than 0"
            }
            
            let drop = GumDrop(
                dropId: dropId,
                amount: amount,
                eligibleUsers: eligibleAddresses,
                durationSeconds: durationSeconds
            )
            
            TestPumpkinDrop420.activeGumDrop = drop
            TestPumpkinDrop420.totalGumDrops = TestPumpkinDrop420.totalGumDrops + 1
            
            emit GumDropCreated(
                dropId: dropId,
                eligibleCount: eligibleAddresses.length,
                amount: amount,
                startTime: drop.startTime,
                endTime: drop.endTime
            )
        }
        
        /// Mark user as claimed (called after Supabase GUM is added)
        access(all) fun markGumClaimed(user: Address) {
            pre {
                TestPumpkinDrop420.activeGumDrop != nil: "No active GumDrop"
            }
            
            if let drop = TestPumpkinDrop420.activeGumDrop {
                drop.markClaimed(user: user)
                
                emit GumDropClaimed(
                    user: user,
                    dropId: drop.dropId,
                    amount: drop.amount,
                    timestamp: getCurrentBlock().timestamp
                )
            }
        }
        
        /// Close the active GumDrop
        access(all) fun closeGumDrop() {
            pre {
                TestPumpkinDrop420.activeGumDrop != nil: "No active GumDrop to close"
            }
            
            if let drop = TestPumpkinDrop420.activeGumDrop {
                emit GumDropClosed(
                    dropId: drop.dropId,
                    totalClaimed: drop.claimedUsers.length,
                    totalEligible: drop.eligibleUsers.length
                )
            }
            
            TestPumpkinDrop420.activeGumDrop = nil
        }
        
        // === CHAPTER 5 COMPLETION MANAGEMENT ===
        
        /// Register slacker completion
        access(all) fun registerSlackerCompletion(userAddress: Address) {
            if TestPumpkinDrop420.chapter5Completions[userAddress] == nil {
                TestPumpkinDrop420.chapter5Completions[userAddress] = Chapter5Status(userAddress: userAddress)
            }
            
            TestPumpkinDrop420.chapter5Completions[userAddress]?.markSlackerComplete()
            
            emit Chapter5SlackerCompleted(
                userAddress: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
            
            // Check if both are complete
            self.checkFullCompletion(userAddress: userAddress)
        }
        
        /// Register overachiever completion
        access(all) fun registerOverachieverCompletion(userAddress: Address) {
            if TestPumpkinDrop420.chapter5Completions[userAddress] == nil {
                TestPumpkinDrop420.chapter5Completions[userAddress] = Chapter5Status(userAddress: userAddress)
            }
            
            TestPumpkinDrop420.chapter5Completions[userAddress]?.markOverachieverComplete()
            
            emit Chapter5OverachieverCompleted(
                userAddress: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
            
            // Check if both are complete
            self.checkFullCompletion(userAddress: userAddress)
        }
        
        /// Check if both achievements complete and emit event
        access(all) fun checkFullCompletion(userAddress: Address) {
            if let status = TestPumpkinDrop420.chapter5Completions[userAddress] {
                if status.isFullyComplete() && !status.nftAirdropped {
                    TestPumpkinDrop420.totalChapter5Completions = TestPumpkinDrop420.totalChapter5Completions + 1
                    
                    emit Chapter5FullCompletion(
                        userAddress: userAddress,
                        timestamp: getCurrentBlock().timestamp
                    )
                }
            }
        }
        
        /// Airdrop Chapter 5 NFT to eligible user
        access(all) fun airdropChapter5NFT(userAddress: Address) {
            assert(TestPumpkinDrop420.isEligibleForChapter5NFT(userAddress: userAddress), message: "User not eligible for Chapter 5 NFT")
            
            // Get recipient's collection capability
            let recipientCap = getAccount(userAddress)
                .capabilities.get<&TestPumpkinDrop420.Chapter5Collection>(TestPumpkinDrop420.Chapter5CollectionPublicPath)
            
            assert(recipientCap.check(), message: "Recipient does not have Chapter 5 collection set up")
            
            let recipient = recipientCap.borrow()!
            
            // Mint NFT
            let nftID = TestPumpkinDrop420.totalChapter5NFTs
            TestPumpkinDrop420.totalChapter5NFTs = TestPumpkinDrop420.totalChapter5NFTs + 1
            
            let nft <- create Chapter5NFT(
                id: nftID,
                recipient: userAddress
            )
            
            // Deposit to recipient
            recipient.deposit(token: <-nft)
            
            // Update completion status
            if let completionStatus = TestPumpkinDrop420.chapter5Completions[userAddress] {
                completionStatus.markNFTAirdropped(nftID: nftID)
            }
            
            emit Chapter5NFTMinted(
                nftID: nftID,
                recipient: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
        }
    }
    
    // ========================================
    // PUBLIC FUNCTIONS
    // ========================================
    
    /// Create user profile (timezone for Paradise Motel day/night)
    access(all) fun createUserProfile(username: String, timezone: Int): @UserProfile {
        return <- create UserProfile(username: username, timezone: timezone)
    }
    
    /// Create empty Chapter 5 collection
    access(all) fun createEmptyChapter5Collection(): @Chapter5Collection {
        return <- create Chapter5Collection()
    }
    
    // ========================================
    // QUERY FUNCTIONS
    // ========================================
    
    /// Check if user is eligible for GumDrop
    access(all) fun isEligibleForGumDrop(user: Address): Bool {
        if let drop = TestPumpkinDrop420.activeGumDrop {
            return drop.isEligible(user: user) && drop.isActive()
        }
        return false
    }
    
    /// Check if user has claimed GumDrop
    access(all) fun hasClaimedGumDrop(user: Address): Bool {
        if let drop = TestPumpkinDrop420.activeGumDrop {
            return drop.hasClaimed(user: user)
        }
        return false
    }
    
    /// Get active GumDrop info
    access(all) fun getGumDropInfo(): {String: AnyStruct}? {
        if let drop = TestPumpkinDrop420.activeGumDrop {
            return {
                "dropId": drop.dropId,
                "amount": drop.amount,
                "startTime": drop.startTime,
                "endTime": drop.endTime,
                "isActive": drop.isActive(),
                "timeRemaining": drop.getTimeRemaining(),
                "totalEligible": drop.eligibleUsers.length,
                "totalClaimed": drop.claimedUsers.length
            }
        }
        return nil
    }
    
    /// Get Chapter 5 status for user
    access(all) fun getChapter5Status(userAddress: Address): Chapter5Status? {
        return TestPumpkinDrop420.chapter5Completions[userAddress]
    }
    
    /// Check if user is eligible for Chapter 5 NFT airdrop
    access(all) fun isEligibleForChapter5NFT(userAddress: Address): Bool {
        if let status = TestPumpkinDrop420.chapter5Completions[userAddress] {
            return status.isFullyComplete() && !status.nftAirdropped
        }
        return false
    }
    
    /// Get contract stats
    access(all) fun getStats(): {String: UInt64} {
        return {
            "totalGumDrops": TestPumpkinDrop420.totalGumDrops,
            "totalChapter5Completions": TestPumpkinDrop420.totalChapter5Completions,
            "totalChapter5NFTs": TestPumpkinDrop420.totalChapter5NFTs
        }
    }
    
    // ========================================
    // INITIALIZATION
    // ========================================
    
    init() {
        // Set storage paths
        self.UserProfileStoragePath = /storage/SemesterZeroProfile
        self.UserProfilePublicPath = /public/SemesterZeroProfile
        self.Chapter5CollectionStoragePath = /storage/SemesterZeroChapter5Collection
        self.Chapter5CollectionPublicPath = /public/SemesterZeroChapter5Collection
        self.AdminStoragePath = /storage/SemesterZeroAdmin
        
        // Initialize state
        self.totalGumDrops = 0
        self.totalChapter5Completions = 0
        self.totalChapter5NFTs = 0
        self.activeGumDrop = nil
        self.chapter5Completions = {}
        
        // Create admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
