import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448

/// SemesterZero - Forte Hackathon Edition
/// 3 Blockchain Features:
/// 1. GumDrop Airdrop (72-hour claim window) - Flow Actions triggers create/close
/// 2. Paradise Motel Day/Night (per-user timezone) - Personalized 12hr cycle using blockchain storage
/// 3. Chapter 5 NFT Airdrop (100% completion) - Auto-airdrop on slacker + overachiever complete
///
/// For flunks.flow deployment - October 2025
access(all) contract SemesterZero: NonFungibleToken, ViewResolver {
    
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
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, recipient: Address)
    
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
        access(all) let serialNumber: UInt64  // Mint order (1st, 2nd, 3rd person to complete)
        access(all) var metadata: {String: String}  // Changed to 'var' so you can update it later
        
        init(id: UInt64, recipient: Address, serialNumber: UInt64) {
            self.id = id
            self.achievementType = "SLACKER_AND_OVERACHIEVER"
            self.recipient = recipient
            self.mintedAt = getCurrentBlock().timestamp
            self.serialNumber = serialNumber
            
            self.metadata = {
                "name": "Paradise Motel",
                "description": "Awarded for completing both Slacker and Overachiever objectives in Chapter 5 of Flunks: Semester Zero",
                "achievement": "SLACKER_AND_OVERACHIEVER",
                "chapter": "5",
                "collection": "Flunks: Semester Zero",
                "serialNumber": serialNumber.toString(),
                "revealed": "false",
                "image": "https://storage.googleapis.com/flunks_public/images/1.png"
            }
        }
        
        // Admin can update metadata for the reveal
        access(contract) fun reveal(newMetadata: {String: String}) {
            self.metadata = newMetadata
        }
        
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Serial>()
            ]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"]!,
                        description: self.metadata["description"]!,
                        thumbnail: MetadataViews.HTTPFile(url: self.metadata["image"]!)
                    )
                
                case Type<MetadataViews.NFTCollectionData>():
                    return SemesterZero.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>())
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return SemesterZero.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>())
                
                case Type<MetadataViews.Royalties>():
                    let royaltyCap = SemesterZero.getRoyaltyReceiverCapability()
                    if !royaltyCap.check() {
                        return MetadataViews.Royalties([])
                    }
                    return MetadataViews.Royalties([
                        MetadataViews.Royalty(
                            receiver: royaltyCap,
                            cut: 0.10,
                            description: "Flunks: Semester Zero creator royalty"
                        )
                    ])

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flunks.flow")
                
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.serialNumber)
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-SemesterZero.createEmptyCollection(nftType: Type<@SemesterZero.Chapter5NFT>())
        }
    }
    
    // ========================================
    // CHAPTER 5 COLLECTION
    // ========================================
    
    access(all) resource Chapter5Collection: NonFungibleToken.Collection, ViewResolver.ResolverCollection {
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
            let nft <- token as! @SemesterZero.Chapter5NFT
            emit Withdraw(id: nft.id, from: self.owner?.address)
            return <-nft
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @SemesterZero.Chapter5NFT
            let id = nft.id
            let oldToken <- self.ownedNFTs[id] <- nft
            destroy oldToken
            emit Deposit(id: id, to: self.owner?.address)
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@SemesterZero.Chapter5NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SemesterZero.Chapter5NFT>()
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-SemesterZero.createEmptyCollection(nftType: Type<@SemesterZero.Chapter5NFT>())
        }
        
        // Borrow specific Chapter5NFT (needed for reveal function)
        access(all) view fun borrowChapter5NFT(id: UInt64): &Chapter5NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
                return ref as! &Chapter5NFT?
            }
            return nil
        }
        
        // MetadataViews.ResolverCollection - Required for Token List
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
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
                SemesterZero.activeGumDrop == nil: "Active GumDrop already exists. Close it first."
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
            
            SemesterZero.activeGumDrop = drop
            SemesterZero.totalGumDrops = SemesterZero.totalGumDrops + 1
            
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
                SemesterZero.activeGumDrop != nil: "No active GumDrop"
            }
            
            if let drop = SemesterZero.activeGumDrop {
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
        
        /// Register slacker completion
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
        
        /// Register overachiever completion
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
        
        /// Airdrop Chapter 5 NFT to eligible user
        access(all) fun airdropChapter5NFT(userAddress: Address) {
            assert(SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress), message: "User not eligible for Chapter 5 NFT")
            
            // Get recipient's collection capability
            let recipientCap = getAccount(userAddress)
                .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
            
            assert(recipientCap.check(), message: "Recipient does not have Chapter 5 collection set up")
            
            let recipient = recipientCap.borrow()!
            
            // Mint NFT
            let nftID = SemesterZero.totalChapter5NFTs
            let serialNumber = SemesterZero.totalChapter5NFTs + 1  // 1st, 2nd, 3rd, etc.
            SemesterZero.totalChapter5NFTs = SemesterZero.totalChapter5NFTs + 1
            
            let nft <- create Chapter5NFT(
                id: nftID,
                recipient: userAddress,
                serialNumber: serialNumber
            )
            
            // Deposit to recipient
            recipient.deposit(token: <-nft)
            emit Minted(id: nftID, recipient: userAddress)
            
            // Update completion status
            if let completionStatus = SemesterZero.chapter5Completions[userAddress] {
                completionStatus.markNFTAirdropped(nftID: nftID)
            }
            
            emit Chapter5NFTMinted(
                nftID: nftID,
                recipient: userAddress,
                timestamp: getCurrentBlock().timestamp
            )
        }
        
        /// Reveal a user's Chapter 5 NFT (update metadata)
        access(all) fun revealChapter5NFT(userAddress: Address, newMetadata: {String: String}) {
            // Get user's collection
            let collectionRef = getAccount(userAddress)
                .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
                .borrow()
                ?? panic("User does not have Chapter 5 collection")
            
            // Get their NFT IDs
            let nftIDs = collectionRef.getIDs()
            assert(nftIDs.length > 0, message: "User has no Chapter 5 NFTs")
            
            // Borrow the NFT and reveal it
            let nftID = nftIDs[0]
            let nftRef = collectionRef.borrowChapter5NFT(id: nftID)
                ?? panic("Could not borrow NFT reference")
            
            nftRef.reveal(newMetadata: newMetadata)
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

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        assert(nftType == Type<@SemesterZero.Chapter5NFT>(), message: "Unsupported NFT type")
        return <- SemesterZero.createEmptyChapter5Collection()
    }

    access(all) fun getRoyaltyReceiverCapability(): Capability<&{FungibleToken.Receiver}> {
        return getAccount(0xbfffec679fff3a94)
            .capabilities
            .get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
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
            "totalGumDrops": SemesterZero.totalGumDrops,
            "totalChapter5Completions": SemesterZero.totalChapter5Completions,
            "totalChapter5NFTs": SemesterZero.totalChapter5NFTs
        }
    }
    
    // ========================================
    // VIEW RESOLVER (for Token List Registration)
    // ========================================
    
    /// Returns the types of supported views - called by tokenlist
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }
    
    /// Resolves a view for this contract - called by tokenlist
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: self.Chapter5CollectionStoragePath,
                    publicPath: self.Chapter5CollectionPublicPath,
                    publicCollection: Type<&Chapter5Collection>(),
                    publicLinkedType: Type<&Chapter5Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-SemesterZero.createEmptyCollection(nftType: Type<@SemesterZero.Chapter5NFT>())
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
        self.AdminStoragePath = /storage/SemesterZeroHackathonAdmin
        
        // Initialize state
        self.totalGumDrops = 0
        self.totalChapter5Completions = 0
        self.totalChapter5NFTs = 0
        self.activeGumDrop = nil
        self.chapter5Completions = {}
        
        // Create admin resource (only if it doesn't exist)
        if self.account.storage.borrow<&Admin>(from: self.AdminStoragePath) == nil {
            let admin <- create Admin()
            self.account.storage.save(<-admin, to: self.AdminStoragePath)
        }
        
        emit ContractInitialized()
    }
}
