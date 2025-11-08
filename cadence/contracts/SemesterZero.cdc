import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

/// SemesterZero - Forte Hackathon Edition
/// 3 Core Features:
/// 1. GumDrop Airdrop (72-hour claim window for Halloween)
/// 2. Day/Night Per-User Timezone (12-hour cycles)
/// 3. Chapter 5 NFT Airdrop (completion rewards)
///
/// For flunks.flow deployment - October 2025
access(all) contract SemesterZero {
    
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
    
    // User Profile Events
    access(all) event ProfileCreated(owner: Address, username: String, timezone: Int)
    access(all) event ProfileUpdated(owner: Address)
    access(all) event TimezoneUpdated(owner: Address, oldTimezone: Int, newTimezone: Int)
    
    // GumDrop Events (72-hour Halloween claim window)
    access(all) event GumDropCreated(dropId: String, eligibleCount: Int, amount: UFix64, startTime: UFix64, endTime: UFix64)
    access(all) event GumDropClaimed(user: Address, dropId: String, amount: UFix64, flunkCount: Int, timestamp: UFix64)
    access(all) event GumDropClosed(dropId: String, totalClaimed: Int, totalEligible: Int)
    
    // Chapter 5 Events
    access(all) event Chapter5SlackerCompleted(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5OverachieverCompleted(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5FullCompletion(userAddress: Address, timestamp: UFix64)
    access(all) event Chapter5NFTMinted(nftID: UInt64, recipient: Address, timestamp: UFix64)
    
    // ========================================
    // STATE VARIABLES
    // ========================================
    
    // User tracking
    access(all) var totalProfiles: UInt64
    
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
    
    /// GumDrop - 72-hour Halloween claim window
    /// Calculates GUM amount based on Flunk NFT ownership (10 GUM per Flunk)
    /// GUM is added to Supabase when claimed, blockchain tracks eligibility
    access(all) struct GumDrop {
        access(all) let dropId: String
        access(all) let gumPerFlunk: UFix64  // 10 GUM per Flunk NFT
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let eligibleUsers: {Address: Bool}
        access(all) var claimedUsers: {Address: ClaimRecord}
        
        init(dropId: String, gumPerFlunk: UFix64, eligibleUsers: [Address], durationSeconds: UFix64) {
            self.dropId = dropId
            self.gumPerFlunk = gumPerFlunk
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
        
        access(all) fun calculateGumAmount(flunkCount: Int): UFix64 {
            return UFix64(flunkCount) * self.gumPerFlunk
        }
        
        access(all) fun markClaimed(user: Address, flunkCount: Int, gumAwarded: UFix64) {
            pre {
                self.eligibleUsers[user] == true: "User not eligible for this drop"
                self.claimedUsers[user] == nil: "User already claimed"
            }
            // Check if active (can't use in pre because getCurrentBlock() is impure)
            assert(self.isActive(), message: "Drop window has expired")
            
            self.claimedUsers[user] = ClaimRecord(
                flunkCount: flunkCount,
                gumAwarded: gumAwarded,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        access(all) fun getTimeRemaining(): UFix64 {
            let now = getCurrentBlock().timestamp
            if now >= self.endTime {
                return 0.0
            }
            return self.endTime - now
        }
    }
    
    /// Claim Record for GumDrop
    access(all) struct ClaimRecord {
        access(all) let flunkCount: Int
        access(all) let gumAwarded: UFix64
        access(all) let timestamp: UFix64
        
        init(flunkCount: Int, gumAwarded: UFix64, timestamp: UFix64) {
            self.flunkCount = flunkCount
            self.gumAwarded = gumAwarded
            self.timestamp = timestamp
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
    // USER PROFILE (Timezone for Day/Night)
    // ========================================
    
    access(all) resource UserProfile {
        access(all) var username: String
        access(all) var timezone: Int  // Hours offset from UTC (-12 to +14)
        access(all) var bio: String
        access(all) var avatar: String
        access(all) let createdAt: UFix64
        
        init(username: String, timezone: Int) {
            self.username = username
            self.timezone = timezone
            self.bio = ""
            self.avatar = ""
            self.createdAt = getCurrentBlock().timestamp
        }
        
        /// Calculate user's local hour (0-23)
        access(all) fun getLocalHour(): Int {
            let timestamp = getCurrentBlock().timestamp
            let utcHour = Int((timestamp / 3600.0) % 24.0)
            var localHour = utcHour + self.timezone
            
            // Wrap around for valid hours (0-23)
            if localHour < 0 {
                localHour = localHour + 24
            } else if localHour >= 24 {
                localHour = localHour - 24
            }
            
            return localHour
        }
        
        /// Check if it's daytime for this user (6 AM - 6 PM)
        access(all) fun isDaytime(): Bool {
            let hour = self.getLocalHour()
            return hour >= 6 && hour < 18
        }
        
        /// Update timezone
        access(all) fun updateTimezone(newTimezone: Int) {
            pre {
                newTimezone >= -12 && newTimezone <= 14: "Timezone must be between -12 and +14"
            }
            
            let oldTimezone = self.timezone
            self.timezone = newTimezone
            
            emit TimezoneUpdated(
                owner: self.owner!.address,
                oldTimezone: oldTimezone,
                newTimezone: newTimezone
            )
        }
        
        /// Update profile info
        access(all) fun updateProfile(username: String?, bio: String?, avatar: String?) {
            if username != nil { self.username = username! }
            if bio != nil { self.bio = bio! }
            if avatar != nil { self.avatar = avatar! }
            
            emit ProfileUpdated(owner: self.owner!.address)
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
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-SemesterZero.createEmptyChapter5Collection()
        }
        
        /// Return the metadata views that this NFT implements
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Serial>()
            ]
        }
        
        /// Resolve a metadata view for this NFT
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"] ?? "Chapter 5 NFT",
                        description: self.metadata["description"] ?? "Flunks: Semester Zero achievement",
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata["image"] ?? "https://storage.googleapis.com/flunks_public/nfts/chapter5-completion.png"
                        )
                    )
                    
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://www.flunks.net/semester-zero/chapter-5")
                    
                case Type<MetadataViews.NFTCollectionData>():
                    return SemesterZero.resolveContractView(resourceType: Type<@SemesterZero.Chapter5NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())
                    
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return SemesterZero.resolveContractView(resourceType: Type<@SemesterZero.Chapter5NFT>(), viewType: Type<MetadataViews.NFTCollectionDisplay>())
                    
                case Type<MetadataViews.Royalties>():
                    // No royalties for Chapter 5 achievement NFTs
                    return MetadataViews.Royalties([])
                    
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
            }
            
            return nil
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
            let nft <- token as! @SemesterZero.Chapter5NFT
            let id = nft.id
            let oldToken <- self.ownedNFTs[id] <- nft
            destroy oldToken
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@SemesterZero.Chapter5NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SemesterZero.Chapter5NFT>()
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-SemesterZero.createEmptyChapter5Collection()
        }
    }
    
    // ========================================
    // ADMIN RESOURCE
    // ========================================
    
    access(all) resource Admin {
        
        // === GUM DROP MANAGEMENT ===
        
        /// Create Halloween GumDrop (72 hours, 10 GUM per Flunk NFT)
        access(all) fun createGumDrop(
            dropId: String,
            eligibleAddresses: [Address],
            gumPerFlunk: UFix64,
            durationSeconds: UFix64
        ) {
            pre {
                SemesterZero.activeGumDrop == nil: "Active GumDrop already exists. Close it first."
                eligibleAddresses.length > 0: "Must have at least one eligible user"
                gumPerFlunk > 0.0: "GUM per Flunk must be greater than 0"
                durationSeconds > 0.0: "Duration must be greater than 0"
            }
            
            let drop = GumDrop(
                dropId: dropId,
                gumPerFlunk: gumPerFlunk,
                eligibleUsers: eligibleAddresses,
                durationSeconds: durationSeconds
            )
            
            SemesterZero.activeGumDrop = drop
            SemesterZero.totalGumDrops = SemesterZero.totalGumDrops + 1
            
            emit GumDropCreated(
                dropId: dropId,
                eligibleCount: eligibleAddresses.length,
                amount: gumPerFlunk,
                startTime: drop.startTime,
                endTime: drop.endTime
            )
        }
        
        /// Mark user as claimed (called after Supabase GUM is added)
        access(all) fun markGumClaimed(user: Address, flunkCount: Int) {
            pre {
                SemesterZero.activeGumDrop != nil: "No active GumDrop"
                flunkCount > 0: "Must own at least one Flunk NFT"
            }
            
            if let drop = SemesterZero.activeGumDrop {
                let gumAwarded = drop.calculateGumAmount(flunkCount: flunkCount)
                drop.markClaimed(user: user, flunkCount: flunkCount, gumAwarded: gumAwarded)
                
                emit GumDropClaimed(
                    user: user,
                    dropId: drop.dropId,
                    amount: gumAwarded,
                    flunkCount: flunkCount,
                    timestamp: getCurrentBlock().timestamp
                )
            }
        }
        
        /// Close the active GumDrop (auto-closes after 72 hours)
        access(all) fun closeGumDrop() {
            pre {
                SemesterZero.activeGumDrop != nil: "No active GumDrop to close"
            }
            
            if let drop = SemesterZero.activeGumDrop {
                emit GumDropClosed(
                    dropId: drop.dropId,
                    totalClaimed: drop.claimedUsers.length,
                    totalEligible: drop.eligibleUsers.length
                )
            }
            
            SemesterZero.activeGumDrop = nil
        }
        
        // === CHAPTER 5 COMPLETION MANAGEMENT ===
        
        /// Register slacker completion (called from backend after Supabase check)
        access(all) fun registerSlackerCompletion(userAddress: Address) {
            if SemesterZero.chapter5Completions[userAddress] == nil {
                SemesterZero.chapter5Completions[userAddress] = Chapter5Status(userAddress: userAddress)
            }
            
            SemesterZero.chapter5Completions[userAddress]?.markSlackerComplete()
            
            emit Chapter5SlackerCompleted(
                userAddress: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
            
            // Check if both are complete
            self.checkFullCompletion(userAddress: userAddress)
        }
        
        /// Register overachiever completion (called from backend after Supabase check)
        access(all) fun registerOverachieverCompletion(userAddress: Address) {
            if SemesterZero.chapter5Completions[userAddress] == nil {
                SemesterZero.chapter5Completions[userAddress] = Chapter5Status(userAddress: userAddress)
            }
            
            SemesterZero.chapter5Completions[userAddress]?.markOverachieverComplete()
            
            emit Chapter5OverachieverCompleted(
                userAddress: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
            
            // Check if both are complete
            self.checkFullCompletion(userAddress: userAddress)
        }
        
        /// Check if both achievements complete and emit event
        access(all) fun checkFullCompletion(userAddress: Address) {
            if let status = SemesterZero.chapter5Completions[userAddress] {
                if status.isFullyComplete() && !status.nftAirdropped {
                    SemesterZero.totalChapter5Completions = SemesterZero.totalChapter5Completions + 1
                    
                    emit Chapter5FullCompletion(
                        userAddress: userAddress,
                        timestamp: getCurrentBlock().timestamp
                    )
                }
            }
        }
        
        /// Airdrop Chapter 5 NFT to eligible user (both objectives complete)
        access(all) fun airdropChapter5NFT(userAddress: Address) {
            // Check eligibility (can't use in pre because it calls getCurrentBlock indirectly)
            assert(SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress), message: "User not eligible for Chapter 5 NFT")
            
            // Get recipient's collection capability
            let recipientCap = getAccount(userAddress)
                .capabilities.get<&{NonFungibleToken.Receiver}>(SemesterZero.Chapter5CollectionPublicPath)
            
            assert(recipientCap.check(), message: "Recipient does not have Chapter 5 collection set up")
            
            let recipient = recipientCap.borrow()!
            
            // Mint NFT
            let nftID = SemesterZero.totalChapter5NFTs
            SemesterZero.totalChapter5NFTs = SemesterZero.totalChapter5NFTs + 1
            
            let nft <- create Chapter5NFT(
                id: nftID,
                recipient: userAddress
            )
            
            // Deposit to recipient
            recipient.deposit(token: <-nft)
            
            // Update completion status
            SemesterZero.chapter5Completions[userAddress]?.markNFTAirdropped(nftID: nftID)
            
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
    
    /// Create a new user profile with timezone
    access(all) fun createUserProfile(username: String, timezone: Int): @UserProfile {
        SemesterZero.totalProfiles = SemesterZero.totalProfiles + 1
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
        if let drop = SemesterZero.activeGumDrop {
            return drop.isEligible(user: user) && drop.isActive()
        }
        return false
    }
    
    /// Check if user has claimed GumDrop
    access(all) fun hasClaimedGumDrop(user: Address): Bool {
        if let drop = SemesterZero.activeGumDrop {
            return drop.hasClaimed(user: user)
        }
        return false
    }
    
    /// Get active GumDrop info
    access(all) fun getGumDropInfo(): {String: AnyStruct}? {
        if let drop = SemesterZero.activeGumDrop {
            return {
                "dropId": drop.dropId,
                "gumPerFlunk": drop.gumPerFlunk,
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
    
    /// Get user's day/night status based on their timezone
    access(all) fun getUserDayNightStatus(userAddress: Address): {String: AnyStruct} {
        let account = getAccount(userAddress)
        let profileRef = account.capabilities
            .get<&UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        if let profile = profileRef {
            let isDaytime = profile.isDaytime()
            let localHour = profile.getLocalHour()
            
            return {
                "userAddress": userAddress.toString(),
                "isDaytime": isDaytime,
                "localHour": localHour,
                "timezone": profile.timezone,
                "imageType": isDaytime ? "day" : "night",
                "imageURL": isDaytime 
                    ? "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png"
                    : "https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png"
            }
        }
        
        // Default to day if no profile
        return {
            "userAddress": userAddress.toString(),
            "isDaytime": true,
            "localHour": 12,
            "timezone": 0,
            "imageType": "day",
            "imageURL": "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png",
            "hasProfile": false
        }
    }
    
    /// Get Chapter 5 status for user
    access(all) fun getChapter5Status(userAddress: Address): Chapter5Status? {
        return SemesterZero.chapter5Completions[userAddress]
    }
    
    /// Check if user is eligible for Chapter 5 NFT airdrop
    access(all) fun isEligibleForChapter5NFT(userAddress: Address): Bool {
        if let status = SemesterZero.chapter5Completions[userAddress] {
            return status.isFullyComplete() && !status.nftAirdropped
        }
        return false
    }
    
    /// Get contract stats
    access(all) fun getStats(): {String: UInt64} {
        return {
            "totalProfiles": SemesterZero.totalProfiles,
            "totalGumDrops": SemesterZero.totalGumDrops,
            "totalChapter5Completions": SemesterZero.totalChapter5Completions,
            "totalChapter5NFTs": SemesterZero.totalChapter5NFTs
        }
    }
    
    // ========================================
    // METADATA VIEWS (CONTRACT-LEVEL)
    // ========================================
    
    /// Return the metadata views that this contract implements
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }
    
    /// Resolve a metadata view for this contract
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: self.Chapter5CollectionStoragePath,
                    publicPath: self.Chapter5CollectionPublicPath,
                    publicCollection: Type<&SemesterZero.Chapter5Collection>(),
                    publicLinkedType: Type<&SemesterZero.Chapter5Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-SemesterZero.createEmptyChapter5Collection()
                    })
                )
                
            case Type<MetadataViews.NFTCollectionDisplay>():
                let squareMedia = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://storage.googleapis.com/flunks_public/images/semesterzero.png"
                    ),
                    mediaType: "image/png"
                )
                let bannerMedia = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://storage.googleapis.com/flunks_public/images/banner.png"
                    ),
                    mediaType: "image/png"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flunks: Semester Zero",
                    description: "Flunks: Semester Zero is a standalone collection that rewards users for exploring flunks.net and participating in events, challenges and completing objectives.",
                    externalURL: MetadataViews.ExternalURL("https://flunks.net"),
                    squareImage: squareMedia,
                    bannerImage: bannerMedia,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/flunks_nft"),
                        "discord": MetadataViews.ExternalURL("https://discord.gg/flunks")
                    }
                )
        }
        
        return nil
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
        self.totalProfiles = 0
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
