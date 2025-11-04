import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe

/// SemesterZero - The comprehensive Flunks ecosystem contract
/// Combines: GUM system, Dynamic NFTs, Achievements, Airdrops, Customization
/// Built for Forte Hackathon 2025 with Flow Actions integration
access(all) contract SemesterZero {
    
    // ========================================
    // PATHS
    // ========================================
    
    access(all) let GumAccountStoragePath: StoragePath
    access(all) let GumAccountPublicPath: PublicPath
    access(all) let UserProfileStoragePath: StoragePath
    access(all) let UserProfilePublicPath: PublicPath
    access(all) let AchievementCollectionStoragePath: StoragePath
    access(all) let AchievementCollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // ========================================
    // EVENTS
    // ========================================
    
    access(all) event ContractInitialized()
    
    // GUM Events
    access(all) event GumAccountCreated(owner: Address, initialBalance: UFix64)
    access(all) event GumTransferred(from: Address, to: Address, amount: UFix64, message: String?)
    access(all) event GumSpent(owner: Address, amount: UFix64, reason: String)
    access(all) event GumSynced(owner: Address, oldBalance: UFix64, newBalance: UFix64)
    
    // Special Drop Events
    access(all) event SpecialDropCreated(dropID: UInt64, name: String, startTime: UFix64, endTime: UFix64)
    access(all) event SpecialDropClaimed(dropID: UInt64, claimer: Address, amount: UFix64)
    
    // Achievement Events
    access(all) event AchievementNFTMinted(id: UInt64, owner: Address, achievementType: String, tier: String)
    access(all) event AchievementTierUpdated(id: UInt64, owner: Address, oldTier: String, newTier: String)
    
    // Airdrop Events
    access(all) event AirdropCreated(airdropID: UInt64, name: String, requiredGUM: UFix64, totalSupply: UInt64)
    access(all) event AirdropClaimed(airdropID: UInt64, claimer: Address, nftID: UInt64)
    
    // Profile Events
    access(all) event ProfileCreated(owner: Address, username: String, timezone: Int)
    access(all) event ProfileUpdated(owner: Address)
    
    // Halloween Events
    access(all) event HalloweenDropCreated(dropId: String, eligibleCount: Int, amount: UFix64, startTime: UFix64, endTime: UFix64)
    access(all) event HalloweenClaimed(user: Address, dropId: String, amount: UFix64, timestamp: UFix64)
    
    // ========================================
    // STATE VARIABLES
    // ========================================
    
    access(all) var totalGumAccounts: UInt64
    access(all) var nextDropID: UInt64
    access(all) var nextAchievementID: UInt64
    access(all) var nextAirdropID: UInt64
    
    // Active drops storage
    access(self) let activeDrops: @{UInt64: SpecialDrop}
    access(self) let airdrops: @{UInt64: Airdrop}
    
    // ========================================
    // USER PROFILE (Timezone & Preferences)
    // ========================================
    
    access(all) resource UserProfile {
        access(all) var username: String
        access(all) var bio: String
        access(all) var avatar: String
        access(all) var timezone: Int  // Hours offset from UTC (-12 to +14)
        access(all) var preferences: {String: String}
        access(all) let createdAt: UFix64
        
        init(username: String, timezone: Int) {
            self.username = username
            self.bio = ""
            self.avatar = ""
            self.timezone = timezone
            self.preferences = {}
            self.createdAt = getCurrentBlock().timestamp
        }
        
        access(all) fun updateProfile(username: String?, bio: String?, avatar: String?, timezone: Int?) {
            if username != nil { self.username = username! }
            if bio != nil { self.bio = bio! }
            if avatar != nil { self.avatar = avatar! }
            if timezone != nil { self.timezone = timezone! }
            
            emit ProfileUpdated(owner: self.owner!.address)
        }
        
        access(all) fun setPreference(key: String, value: String) {
            self.preferences[key] = value
        }
        
        access(all) fun getLocalHour(): Int {
            let timestamp = getCurrentBlock().timestamp
            let utcHour = Int((timestamp / 3600) % 24)
            var localHour = utcHour + self.timezone
            
            // Wrap around for valid hours (0-23)
            if localHour < 0 {
                localHour = localHour + 24
            } else if localHour >= 24 {
                localHour = localHour - 24
            }
            
            return localHour
        }
        
        access(all) fun isDaytime(): Bool {
            let hour = self.getLocalHour()
            // Daytime: 6 AM (6) to 6 PM (18)
            return hour >= 6 && hour < 18
        }
    }
    
    // ========================================
    // GUM ACCOUNT (Hybrid On-Chain Ledger)
    // ========================================
    
    access(all) resource interface GumAccountPublic {
        access(all) fun getBalance(): UFix64
        access(all) fun getInfo(): GumInfo
        access(all) fun deposit(amount: UFix64)
    }
    
    access(all) struct GumInfo {
        access(all) let balance: UFix64
        access(all) let totalEarned: UFix64
        access(all) let totalSpent: UFix64
        access(all) let totalTransferred: UFix64
        access(all) let lastSyncTimestamp: UFix64
        access(all) let owner: Address
        
        init(
            balance: UFix64,
            totalEarned: UFix64,
            totalSpent: UFix64,
            totalTransferred: UFix64,
            lastSyncTimestamp: UFix64,
            owner: Address
        ) {
            self.balance = balance
            self.totalEarned = totalEarned
            self.totalSpent = totalSpent
            self.totalTransferred = totalTransferred
            self.lastSyncTimestamp = lastSyncTimestamp
            self.owner = owner
        }
    }
    
    access(all) resource GumAccount: GumAccountPublic {
        access(all) var balance: UFix64
        access(all) var totalEarned: UFix64
        access(all) var totalSpent: UFix64
        access(all) var totalTransferred: UFix64
        access(all) var lastSyncTimestamp: UFix64
        
        init(initialBalance: UFix64) {
            self.balance = initialBalance
            self.totalEarned = initialBalance
            self.totalSpent = 0.0
            self.totalTransferred = 0.0
            self.lastSyncTimestamp = getCurrentBlock().timestamp
        }
        
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        access(all) fun getInfo(): GumInfo {
            return GumInfo(
                balance: self.balance,
                totalEarned: self.totalEarned,
                totalSpent: self.totalSpent,
                totalTransferred: self.totalTransferred,
                lastSyncTimestamp: self.lastSyncTimestamp,
                owner: self.owner!.address
            )
        }
        
        access(all) fun deposit(amount: UFix64) {
            self.balance = self.balance + amount
            self.totalEarned = self.totalEarned + amount
        }
        
        // Transfer GUM to another user (on-chain transparency)
        access(all) fun transfer(amount: UFix64, to: Address, message: String?) {
            pre {
                self.balance >= amount: "Insufficient GUM balance"
                amount > 0.0: "Transfer amount must be positive"
            }
            
            // Deduct from sender
            self.balance = self.balance - amount
            self.totalTransferred = self.totalTransferred + amount
            
            // Add to recipient
            let recipient = getAccount(to)
            let recipientGumAccount = recipient.capabilities
                .get<&GumAccount>(SemesterZero.GumAccountPublicPath)
                .borrow()
                ?? panic("Recipient does not have a GUM account")
            
            recipientGumAccount.deposit(amount: amount)
            
            emit GumTransferred(
                from: self.owner!.address,
                to: to,
                amount: amount,
                message: message
            )
        }
        
        // Spend GUM (tracked but not transferred)
        access(all) fun spend(amount: UFix64, reason: String, metadata: {String: String}) {
            pre {
                self.balance >= amount: "Insufficient GUM balance"
                amount > 0.0: "Spend amount must be positive"
            }
            
            self.balance = self.balance - amount
            self.totalSpent = self.totalSpent + amount
            
            emit GumSpent(owner: self.owner!.address, amount: amount, reason: reason)
        }
        
        // Admin sync from Supabase
        access(account) fun syncBalance(newBalance: UFix64) {
            let oldBalance = self.balance
            
            if newBalance > oldBalance {
                let earned = newBalance - oldBalance
                self.totalEarned = self.totalEarned + earned
            }
            
            self.balance = newBalance
            self.lastSyncTimestamp = getCurrentBlock().timestamp
            
            emit GumSynced(owner: self.owner!.address, oldBalance: oldBalance, newBalance: newBalance)
        }
    }
    
    // ========================================
    // SPECIAL DROPS (Time-Limited Events)
    // ========================================
    
    access(all) struct SpecialDropInfo {
        access(all) let dropID: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let amount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let requiredFlunks: Bool
        access(all) let minFlunksCount: Int
        access(all) let totalClaims: UInt64
        access(all) let maxClaims: UInt64
        access(all) let isActive: Bool
        
        init(
            dropID: UInt64,
            name: String,
            description: String,
            amount: UFix64,
            startTime: UFix64,
            endTime: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            totalClaims: UInt64,
            maxClaims: UInt64,
            isActive: Bool
        ) {
            self.dropID = dropID
            self.name = name
            self.description = description
            self.amount = amount
            self.startTime = startTime
            self.endTime = endTime
            self.requiredFlunks = requiredFlunks
            self.minFlunksCount = minFlunksCount
            self.totalClaims = totalClaims
            self.maxClaims = maxClaims
            self.isActive = isActive
        }
    }
    
    access(all) resource SpecialDrop {
        access(all) let dropID: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let amount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let requiredFlunks: Bool
        access(all) let minFlunksCount: Int
        access(all) let maxClaims: UInt64
        access(all) var totalClaims: UInt64
        access(contract) let claimers: {Address: Bool}
        
        init(
            name: String,
            description: String,
            amount: UFix64,
            startTime: UFix64,
            endTime: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            maxClaims: UInt64
        ) {
            self.dropID = SemesterZero.nextDropID
            SemesterZero.nextDropID = SemesterZero.nextDropID + 1
            
            self.name = name
            self.description = description
            self.amount = amount
            self.startTime = startTime
            self.endTime = endTime
            self.requiredFlunks = requiredFlunks
            self.minFlunksCount = minFlunksCount
            self.maxClaims = maxClaims
            self.totalClaims = 0
            self.claimers = {}
            
            emit SpecialDropCreated(
                dropID: self.dropID,
                name: name,
                startTime: startTime,
                endTime: endTime
            )
        }
        
        access(all) fun isActive(): Bool {
            let now = getCurrentBlock().timestamp
            return now >= self.startTime && now <= self.endTime && self.totalClaims < self.maxClaims
        }
        
        access(all) fun getInfo(): SpecialDropInfo {
            return SpecialDropInfo(
                dropID: self.dropID,
                name: self.name,
                description: self.description,
                amount: self.amount,
                startTime: self.startTime,
                endTime: self.endTime,
                requiredFlunks: self.requiredFlunks,
                minFlunksCount: self.minFlunksCount,
                totalClaims: self.totalClaims,
                maxClaims: self.maxClaims,
                isActive: self.isActive()
            )
        }
        
        access(contract) fun claim(claimer: Address, gumAccount: &GumAccount) {
            pre {
                self.isActive(): "Drop is not active"
                self.claimers[claimer] == nil: "Already claimed this drop"
            }
            
            // Check Flunks ownership if required
            if self.requiredFlunks {
                let account = getAccount(claimer)
                let flunksCollection = account.capabilities
                    .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
                    .borrow()
                
                assert(
                    flunksCollection != nil && flunksCollection!.getIDs().length >= self.minFlunksCount,
                    message: "Must own at least ".concat(self.minFlunksCount.toString()).concat(" Flunks to claim")
                )
            }
            
            // Award GUM
            gumAccount.deposit(amount: self.amount)
            
            // Mark as claimed
            self.claimers[claimer] = true
            self.totalClaims = self.totalClaims + 1
            
            emit SpecialDropClaimed(dropID: self.dropID, claimer: claimer, amount: self.amount)
        }
    }
    
    // ========================================
    // ACHIEVEMENT NFTs (Evolving Based on GUM)
    // ========================================
    
    access(all) resource AchievementNFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(all) let achievementType: String  // "gum_earner", "tipper", "early_supporter"
        access(all) let mintedAt: UFix64
        
        init(achievementType: String) {
            self.id = SemesterZero.nextAchievementID
            SemesterZero.nextAchievementID = SemesterZero.nextAchievementID + 1
            self.achievementType = achievementType
            self.mintedAt = getCurrentBlock().timestamp
        }
        
        // Calculate current tier based on owner's GUM balance
        access(all) fun getCurrentTier(): String {
            let owner = self.owner!.address
            let account = getAccount(owner)
            let gumAccount = account.capabilities
                .get<&{GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
                .borrow()
            
            if let gum = gumAccount {
                let info = gum.getInfo()
                
                switch self.achievementType {
                    case "gum_earner":
                        return self.getGumEarnerTier(balance: info.totalEarned)
                    case "tipper":
                        return self.getTipperTier(totalTransferred: info.totalTransferred)
                    case "spender":
                        return self.getSpenderTier(totalSpent: info.totalSpent)
                    default:
                        return "Bronze"
                }
            }
            
            return "Bronze"
        }
        
        access(self) fun getGumEarnerTier(balance: UFix64): String {
            if balance >= 10000.0 { return "Diamond" }
            if balance >= 5000.0 { return "Platinum" }
            if balance >= 1000.0 { return "Gold" }
            if balance >= 500.0 { return "Silver" }
            return "Bronze"
        }
        
        access(self) fun getTipperTier(totalTransferred: UFix64): String {
            if totalTransferred >= 1000.0 { return "Legendary Tipper" }
            if totalTransferred >= 500.0 { return "Very Generous" }
            if totalTransferred >= 100.0 { return "Generous" }
            if totalTransferred >= 25.0 { return "Supporter" }
            return "Newcomer"
        }
        
        access(self) fun getSpenderTier(totalSpent: UFix64): String {
            if totalSpent >= 5000.0 { return "Big Spender" }
            if totalSpent >= 2000.0 { return "Frequent Shopper" }
            if totalSpent >= 500.0 { return "Customer" }
            if totalSpent >= 100.0 { return "Browser" }
            return "Window Shopper"
        }
        
        access(self) fun getTierNumber(tier: String): UInt64 {
            switch tier {
                case "Diamond": return 5
                case "Platinum": return 4
                case "Gold": return 3
                case "Silver": return 2
                case "Bronze": return 1
                case "Legendary Tipper": return 5
                case "Very Generous": return 4
                case "Generous": return 3
                case "Supporter": return 2
                case "Newcomer": return 1
                case "Big Spender": return 5
                case "Frequent Shopper": return 4
                case "Customer": return 3
                case "Browser": return 2
                case "Window Shopper": return 1
                default: return 1
            }
        }
        
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Editions>()
            ]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            let tier = self.getCurrentTier()
            
            switch view {
                case Type<MetadataViews.Display>():
                    let tierLower = tier.toLower()
                    let typeLower = self.achievementType.toLower()
                    
                    return MetadataViews.Display(
                        name: tier.concat(" ").concat(self.achievementType.concat(" Achievement")),
                        description: "This achievement evolves as you earn more GUM! Current tier: ".concat(tier),
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://storage.googleapis.com/flunks_public/achievements/"
                                .concat(typeLower)
                                .concat("_")
                                .concat(tierLower)
                                .concat(".png")
                        )
                    )
                
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flunks.net/achievements")
                
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SemesterZero.AchievementCollectionStoragePath,
                        publicPath: SemesterZero.AchievementCollectionPublicPath,
                        publicCollection: Type<&AchievementCollection>(),
                        publicLinkedType: Type<&AchievementCollection>(),
                        createEmptyCollectionFunction: fun(): @{NonFungibleToken.Collection} {
                            return <- SemesterZero.createEmptyAchievementCollection()
                        }
                    )
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-banner.png"),
                        mediaType: "image/png"
                    )
                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-logo.png"),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Semester Zero Achievements",
                        description: "Dynamic achievement NFTs that evolve as you earn GUM in the Flunks ecosystem. Unlock higher tiers by reaching milestones!",
                        externalURL: MetadataViews.ExternalURL("https://flunks.net/semester-zero"),
                        squareImage: squareMedia,
                        bannerImage: bannerMedia,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/flunks")
                        }
                    )
                
                case Type<MetadataViews.Royalties>():
                    // 5% royalty to Flunks creator
                    let merchant = getAccount(0x0cce91b08cb58286)
                    let royalty = MetadataViews.Royalty(
                        receiver: merchant.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!,
                        cut: 0.05,
                        description: "Flunks creator royalty in DUC"
                    )
                    return MetadataViews.Royalties([royalty])
                
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
                
                case Type<MetadataViews.Editions>():
                    let tierNumber = self.getTierNumber(tier: tier)
                    return MetadataViews.Editions([
                        MetadataViews.Edition(
                            name: tier.concat(" Tier"),
                            number: tierNumber,
                            max: nil
                        )
                    ])
                
                case Type<MetadataViews.Traits>():
                    return MetadataViews.Traits([
                        MetadataViews.Trait(name: "type", value: self.achievementType, displayType: "String", rarity: nil),
                        MetadataViews.Trait(name: "tier", value: tier, displayType: "String", rarity: nil),
                        MetadataViews.Trait(name: "minted_at", value: self.mintedAt.toString(), displayType: "Date", rarity: nil)
                    ])
            }
            
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- SemesterZero.createEmptyAchievementCollection()
        }
    }
    
    access(all) resource AchievementCollection: NonFungibleToken.Collection, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Achievement NFT not found")
            return <- token
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let achievement <- token as! @AchievementNFT
            let id = achievement.id
            self.ownedNFTs[id] <-! achievement
        }
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(all) fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as! &AchievementNFT
            }
            return nil
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@AchievementNFT>()] = true
            return supportedTypes
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@AchievementNFT>()
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- SemesterZero.createEmptyAchievementCollection()
        }
    }
    
    // ========================================
    // AIRDROP SYSTEM (GUM-Gated NFT Claims)
    // ========================================
    
    access(all) struct AirdropInfo {
        access(all) let airdropID: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let requiredGUM: UFix64
        access(all) let requiredFlunks: Bool
        access(all) let minFlunksCount: Int
        access(all) let totalSupply: UInt64
        access(all) let claimCount: UInt64
        access(all) let isActive: Bool
        
        init(
            airdropID: UInt64,
            name: String,
            description: String,
            requiredGUM: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            totalSupply: UInt64,
            claimCount: UInt64,
            isActive: Bool
        ) {
            self.airdropID = airdropID
            self.name = name
            self.description = description
            self.requiredGUM = requiredGUM
            self.requiredFlunks = requiredFlunks
            self.minFlunksCount = minFlunksCount
            self.totalSupply = totalSupply
            self.claimCount = claimCount
            self.isActive = isActive
        }
    }
    
    access(all) resource Airdrop {
        access(all) let airdropID: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let requiredGUM: UFix64
        access(all) let requiredFlunks: Bool
        access(all) let minFlunksCount: Int
        access(all) let totalSupply: UInt64
        access(all) var claimCount: UInt64
        access(all) let achievementType: String
        access(contract) let claimers: {Address: Bool}
        
        init(
            name: String,
            description: String,
            requiredGUM: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            totalSupply: UInt64,
            achievementType: String
        ) {
            self.airdropID = SemesterZero.nextAirdropID
            SemesterZero.nextAirdropID = SemesterZero.nextAirdropID + 1
            
            self.name = name
            self.description = description
            self.requiredGUM = requiredGUM
            self.requiredFlunks = requiredFlunks
            self.minFlunksCount = minFlunksCount
            self.totalSupply = totalSupply
            self.claimCount = 0
            self.achievementType = achievementType
            self.claimers = {}
            
            emit AirdropCreated(
                airdropID: self.airdropID,
                name: name,
                requiredGUM: requiredGUM,
                totalSupply: totalSupply
            )
        }
        
        access(all) fun isActive(): Bool {
            return self.claimCount < self.totalSupply
        }
        
        access(all) fun getInfo(): AirdropInfo {
            return AirdropInfo(
                airdropID: self.airdropID,
                name: self.name,
                description: self.description,
                requiredGUM: self.requiredGUM,
                requiredFlunks: self.requiredFlunks,
                minFlunksCount: self.minFlunksCount,
                totalSupply: self.totalSupply,
                claimCount: self.claimCount,
                isActive: self.isActive()
            )
        }
        
        access(contract) fun claim(
            claimer: Address,
            achievementCollection: &AchievementCollection
        ): UInt64 {
            pre {
                self.isActive(): "Airdrop depleted"
                self.claimers[claimer] == nil: "Already claimed"
            }
            
            // Check GUM balance
            let account = getAccount(claimer)
            let gumAccount = account.capabilities
                .get<&{GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
                .borrow()
                ?? panic("No GUM account found")
            
            assert(
                gumAccount.getBalance() >= self.requiredGUM,
                message: "Insufficient GUM balance. Need ".concat(self.requiredGUM.toString())
            )
            
            // Check Flunks if required
            if self.requiredFlunks {
                let flunksCollection = account.capabilities
                    .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
                    .borrow()
                
                assert(
                    flunksCollection != nil && flunksCollection!.getIDs().length >= self.minFlunksCount,
                    message: "Must own at least ".concat(self.minFlunksCount.toString()).concat(" Flunks")
                )
            }
            
            // Mint Achievement NFT
            let achievement <- create AchievementNFT(achievementType: self.achievementType)
            let nftID = achievement.id
            
            achievementCollection.deposit(token: <- achievement)
            
            // Mark as claimed
            self.claimers[claimer] = true
            self.claimCount = self.claimCount + 1
            
            emit AirdropClaimed(airdropID: self.airdropID, claimer: claimer, nftID: nftID)
            
            return nftID
        }
    }
    
    // ========================================
    // ADMIN RESOURCE
    // ========================================
    
    access(all) resource Admin {
        
        // Sync user's GUM balance from Supabase
        access(all) fun syncUserBalance(userAddress: Address, newBalance: UFix64) {
            let account = getAccount(userAddress)
            let gumAccount = account.capabilities
                .get<&GumAccount>(SemesterZero.GumAccountPublicPath)
                .borrow()
                ?? panic("User does not have a GUM account")
            
            gumAccount.syncBalance(newBalance: newBalance)
        }
        
        // Create special drop event
        access(all) fun createSpecialDrop(
            name: String,
            description: String,
            amount: UFix64,
            startTime: UFix64,
            endTime: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            maxClaims: UInt64
        ) {
            let drop <- create SpecialDrop(
                name: name,
                description: description,
                amount: amount,
                startTime: startTime,
                endTime: endTime,
                requiredFlunks: requiredFlunks,
                minFlunksCount: minFlunksCount,
                maxClaims: maxClaims
            )
            
            let dropID = drop.dropID
            SemesterZero.activeDrops[dropID] <-! drop
        }
        
        // Create airdrop campaign
        access(all) fun createAirdrop(
            name: String,
            description: String,
            requiredGUM: UFix64,
            requiredFlunks: Bool,
            minFlunksCount: Int,
            totalSupply: UInt64,
            achievementType: String
        ) {
            let airdrop <- create Airdrop(
                name: name,
                description: description,
                requiredGUM: requiredGUM,
                requiredFlunks: requiredFlunks,
                minFlunksCount: minFlunksCount,
                totalSupply: totalSupply,
                achievementType: achievementType
            )
            
            let airdropID = airdrop.airdropID
            SemesterZero.airdrops[airdropID] <-! airdrop
        }
        
        // Mint achievement NFT directly (for special occasions)
        access(all) fun mintAchievement(
            recipient: Address,
            achievementType: String
        ) {
            let account = getAccount(recipient)
            let receiverRef = account.capabilities
                .get<&AchievementCollection>(SemesterZero.AchievementCollectionPublicPath)
                .borrow()
                ?? panic("Could not borrow achievement collection")
            
            let achievement <- create AchievementNFT(achievementType: achievementType)
            let nftID = achievement.id
            
            receiverRef.deposit(token: <- achievement)
            
            emit AchievementNFTMinted(
                id: nftID,
                owner: recipient,
                achievementType: achievementType,
                tier: "Bronze"
            )
        }
        
        // ========================================
        // HALLOWEEN DROP ADMIN FUNCTIONS
        // ========================================
        
        /// Create Halloween drop with eligible users (eligibility only, no GUM transferred)
        access(all) fun createHalloweenDrop(
            dropId: String,
            eligibleAddresses: [Address],
            amount: UFix64
        ) {
            let drop = HalloweenDrop(
                dropId: dropId,
                amount: amount,
                eligibleUsers: eligibleAddresses
            )
            
            SemesterZero.halloweenDrop = drop
            
            emit HalloweenDropCreated(
                dropId: dropId,
                eligibleCount: eligibleAddresses.length,
                amount: amount,
                startTime: drop.startTime,
                endTime: drop.endTime
            )
        }
        
        /// Mark user as claimed (called after Supabase GUM is added)
        access(all) fun markHalloweenClaimed(_ user: Address) {
            if let drop = SemesterZero.halloweenDrop {
                drop.markClaimed(user: user)
                
                emit HalloweenClaimed(
                    user: user,
                    dropId: drop.dropId,
                    amount: drop.amount,
                    timestamp: getCurrentBlock().timestamp
                )
            } else {
                panic("No active Halloween drop")
            }
        }
        
        /// Clear Halloween drop (after event ends)
        access(all) fun clearHalloweenDrop() {
            SemesterZero.halloweenDrop = nil
        }
    }
    
    // ========================================
    // PUBLIC FUNCTIONS
    // ========================================
    
    // Create GUM account
    access(all) fun createGumAccount(initialBalance: UFix64): @GumAccount {
        SemesterZero.totalGumAccounts = SemesterZero.totalGumAccounts + 1
        return <- create GumAccount(initialBalance: initialBalance)
    }
    
    // Create user profile
    access(all) fun createUserProfile(username: String, timezone: Int): @UserProfile {
        return <- create UserProfile(username: username, timezone: timezone)
    }
    
    // Create empty achievement collection
    access(all) fun createEmptyAchievementCollection(): @AchievementCollection {
        return <- create AchievementCollection()
    }
    
    // Get active drops
    access(all) fun getActiveDrops(): [SpecialDropInfo] {
        let drops: [SpecialDropInfo] = []
        
        for dropID in self.activeDrops.keys {
            let dropRef = &self.activeDrops[dropID] as &SpecialDrop?
            if let drop = dropRef {
                if drop.isActive() {
                    drops.append(drop.getInfo())
                }
            }
        }
        
        return drops
    }
    
    // Get drop info
    access(all) fun getDropInfo(dropID: UInt64): SpecialDropInfo? {
        let dropRef = &self.activeDrops[dropID] as &SpecialDrop?
        return dropRef?.getInfo()
    }
    
    // Claim special drop
    access(all) fun claimSpecialDrop(dropID: UInt64, gumAccount: &GumAccount) {
        let dropRef = &self.activeDrops[dropID] as &SpecialDrop?
            ?? panic("Drop not found")
        
        dropRef.claim(claimer: gumAccount.owner!.address, gumAccount: gumAccount)
    }
    
    // Get active airdrops
    access(all) fun getActiveAirdrops(): [AirdropInfo] {
        let airdrops: [AirdropInfo] = []
        
        for airdropID in self.airdrops.keys {
            let airdropRef = &self.airdrops[airdropID] as &Airdrop?
            if let airdrop = airdropRef {
                if airdrop.isActive() {
                    airdrops.append(airdrop.getInfo())
                }
            }
        }
        
        return airdrops
    }
    
    // Claim airdrop
    access(all) fun claimAirdrop(
        airdropID: UInt64,
        claimer: Address,
        achievementCollection: &AchievementCollection
    ): UInt64 {
        let airdropRef = &self.airdrops[airdropID] as &Airdrop?
            ?? panic("Airdrop not found")
        
        return airdropRef.claim(claimer: claimer, achievementCollection: achievementCollection)
    }
    
    // Check if user is eligible for airdrop
    access(all) fun checkAirdropEligibility(
        claimer: Address,
        airdropID: UInt64
    ): Bool {
        let airdropRef = &self.airdrops[airdropID] as &Airdrop?
            ?? panic("Airdrop not found")
        
        if !airdropRef.isActive() {
            return false
        }
        
        if airdropRef.claimers[claimer] != nil {
            return false
        }
        
        let account = getAccount(claimer)
        
        // Check GUM
        let gumAccount = account.capabilities
            .get<&{GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
            .borrow()
        
        if gumAccount == nil || gumAccount!.getBalance() < airdropRef.requiredGUM {
            return false
        }
        
        // Check Flunks if required
        if airdropRef.requiredFlunks {
            let flunksCollection = account.capabilities
                .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
                .borrow()
            
            if flunksCollection == nil || flunksCollection!.getIDs().length < airdropRef.minFlunksCount {
                return false
            }
        }
        
        return true
    }
    
    // ========================================
    // FLUNKS DYNAMIC VIEWS (Day/Night Support)
    // ========================================
    
    /// Get Flunks NFT with dynamic day/night imagery based on owner's timezone
    /// Note: Requires Flunks contract to be imported separately in calling context
    access(all) fun getFlunksDynamicDisplay(
        flunksNFTMetadata: {String: String},
        flunksName: String,
        flunksTemplateID: UInt64,
        ownerAddress: Address
    ): DynamicDisplay {
        
        // Try to get owner's timezone profile
        let account = getAccount(ownerAddress)
        let profileRef = account.capabilities
            .get<&UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        // Determine which image to show
        var imageURL = flunksNFTMetadata["uri"] ?? ""
        var timeContext = "default"
        
        if let profile = profileRef {
            let isDaytime = profile.isDaytime()
            timeContext = isDaytime ? "day" : "night"
            
            // Check if this Flunks has day/night variants
            if flunksNFTMetadata["dayImageUri"] != nil && flunksNFTMetadata["nightImageUri"] != nil {
                imageURL = isDaytime ? flunksNFTMetadata["dayImageUri"]! : flunksNFTMetadata["nightImageUri"]!
            }
        }
        
        return DynamicDisplay(
            name: flunksName.concat(" #").concat(flunksTemplateID.toString()),
            imageURL: imageURL,
            timeContext: timeContext
        )
    }
    
    access(all) struct DynamicDisplay {
        access(all) let name: String
        access(all) let imageURL: String
        access(all) let timeContext: String  // "day", "night", or "default"
        
        init(name: String, imageURL: String, timeContext: String) {
            self.name = name
            self.imageURL = imageURL
            self.timeContext = timeContext
        }
    }
    
    /// Get comprehensive owner stats (aggregates from multiple sources)
    access(all) fun getOwnerStats(ownerAddress: Address): OwnerStats? {
        let account = getAccount(ownerAddress)
        
        // Get Flunks count
        let flunksCollection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
            .borrow()
        let flunksCount = flunksCollection?.getIDs().length ?? 0
        
        // Get GUM info
        let gumAccount = account.capabilities
            .get<&{GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
            .borrow()
        let gumInfo = gumAccount?.getInfo()
        
        // Get Profile info
        let profile = account.capabilities
            .get<&UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        // Get Achievement count
        let achievementCollection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(SemesterZero.AchievementCollectionPublicPath)
            .borrow()
        let achievementCount = achievementCollection?.getIDs().length ?? 0
        
        if profile == nil {
            return nil
        }
        
        return OwnerStats(
            address: ownerAddress,
            username: profile!.username,
            bio: profile!.bio,
            avatar: profile!.avatar,
            flunksOwned: flunksCount,
            gumBalance: gumInfo?.balance ?? 0.0,
            gumTotalEarned: gumInfo?.totalEarned ?? 0.0,
            gumTotalSpent: gumInfo?.totalSpent ?? 0.0,
            gumTotalTransferred: gumInfo?.totalTransferred ?? 0.0,
            achievementsUnlocked: achievementCount,
            timezone: profile!.timezone,
            isDaytime: profile!.isDaytime(),
            localHour: profile!.getLocalHour(),
            accountAge: getCurrentBlock().timestamp - profile!.createdAt
        )
    }
    
    access(all) struct OwnerStats {
        access(all) let address: Address
        access(all) let username: String
        access(all) let bio: String
        access(all) let avatar: String
        access(all) let flunksOwned: Int
        access(all) let gumBalance: UFix64
        access(all) let gumTotalEarned: UFix64
        access(all) let gumTotalSpent: UFix64
        access(all) let gumTotalTransferred: UFix64
        access(all) let achievementsUnlocked: Int
        access(all) let timezone: Int
        access(all) let isDaytime: Bool
        access(all) let localHour: Int
        access(all) let accountAge: UFix64
        
        init(
            address: Address,
            username: String,
            bio: String,
            avatar: String,
            flunksOwned: Int,
            gumBalance: UFix64,
            gumTotalEarned: UFix64,
            gumTotalSpent: UFix64,
            gumTotalTransferred: UFix64,
            achievementsUnlocked: Int,
            timezone: Int,
            isDaytime: Bool,
            localHour: Int,
            accountAge: UFix64
        ) {
            self.address = address
            self.username = username
            self.bio = bio
            self.avatar = avatar
            self.flunksOwned = flunksOwned
            self.gumBalance = gumBalance
            self.gumTotalEarned = gumTotalEarned
            self.gumTotalSpent = gumTotalSpent
            self.gumTotalTransferred = gumTotalTransferred
            self.achievementsUnlocked = achievementsUnlocked
            self.timezone = timezone
            self.isDaytime = isDaytime
            self.localHour = localHour
            self.accountAge = accountAge
        }
    }
    
    // ========================================
    // FLOW ACTIONS INTEGRATION (Forte Upgrade)
    // ========================================
    
    /// Virtual GUM Vault - Represents Supabase GUM being moved to blockchain
    /// This is NOT a real fungible token - it's a marker for Flow Actions workflows
    access(all) resource VirtualGumVault {
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
        
        access(all) fun withdraw(amount: UFix64): @VirtualGumVault {
            pre {
                self.balance >= amount: "Insufficient balance in virtual vault"
            }
            self.balance = self.balance - amount
            return <- create VirtualGumVault(balance: amount)
        }
        
        access(all) fun deposit(from: @VirtualGumVault) {
            self.balance = self.balance + from.balance
            destroy from
        }
        
        access(all) fun createEmptyVault(): @VirtualGumVault {
            return <- create VirtualGumVault(balance: 0.0)
        }
        
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount
        }
        
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
    }
    
    /// Helper: Create virtual GUM vault for Flow Actions
    access(all) fun createVirtualGumVault(amount: UFix64): @VirtualGumVault {
        return <- create VirtualGumVault(balance: amount)
    }
    
    // ========================================
    // HALLOWEEN CLAIM SYSTEM
    // ========================================
    
    /// Halloween Drop - Eligibility tracker (GUM added in Supabase, not blockchain)
    access(all) struct HalloweenDrop {
        access(all) let dropId: String
        access(all) let amount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let eligibleUsers: {Address: Bool}
        access(all) var claimedUsers: {Address: UFix64}
        
        init(dropId: String, amount: UFix64, eligibleUsers: [Address]) {
            self.dropId = dropId
            self.amount = amount
            self.startTime = getCurrentBlock().timestamp
            self.endTime = self.startTime + 604800.0 // 7 days to claim
            self.eligibleUsers = {}
            self.claimedUsers = {}
            
            for addr in eligibleUsers {
                self.eligibleUsers[addr] = true
            }
        }
        
        access(all) fun markClaimed(user: Address) {
            pre {
                self.eligibleUsers[user] == true: "User not eligible for this drop"
                self.claimedUsers[user] == nil: "User already claimed"
                getCurrentBlock().timestamp <= self.endTime: "Drop has expired"
            }
            self.claimedUsers[user] = getCurrentBlock().timestamp
        }
        
        access(all) fun isEligible(user: Address): Bool {
            return self.eligibleUsers[user] == true && self.claimedUsers[user] == nil
        }
        
        access(all) fun hasClaimed(user: Address): Bool {
            return self.claimedUsers[user] != nil
        }
    }
    
    /// Store active Halloween drop
    access(all) var halloweenDrop: HalloweenDrop?
    
    /// Check if user is eligible for Halloween drop
    access(all) fun isEligibleForHalloween(_ user: Address): Bool {
        if let drop = SemesterZero.halloweenDrop {
            return drop.isEligible(user: user)
        }
        return false
    }
    
    /// Check if user already claimed Halloween drop
    access(all) fun hasClaimedHalloween(_ user: Address): Bool {
        if let drop = SemesterZero.halloweenDrop {
            return drop.hasClaimed(user: user)
        }
        return false
    }
    
    /// Get Halloween drop info
    access(all) fun getHalloweenDropInfo(): {String: AnyStruct}? {
        if let drop = SemesterZero.halloweenDrop {
            return {
                "dropId": drop.dropId,
                "amount": drop.amount,
                "startTime": drop.startTime,
                "endTime": drop.endTime,
                "totalEligible": drop.eligibleUsers.length,
                "totalClaimed": drop.claimedUsers.length
            }
        }
        return nil
    }
    
    // ========================================
    // INIT
    // ========================================
    
    init() {
        // Set paths
        self.GumAccountStoragePath = /storage/SemesterZeroGumAccount
        self.GumAccountPublicPath = /public/SemesterZeroGumAccount
        self.UserProfileStoragePath = /storage/SemesterZeroProfile
        self.UserProfilePublicPath = /public/SemesterZeroProfile
        self.AchievementCollectionStoragePath = /storage/SemesterZeroAchievements
        self.AchievementCollectionPublicPath = /public/SemesterZeroAchievements
        self.AdminStoragePath = /storage/SemesterZeroAdmin
        
        // Initialize state
        self.totalGumAccounts = 0
        self.nextDropID = 1
        self.nextAchievementID = 1
        self.nextAirdropID = 1
        
        self.activeDrops <- {}
        self.airdrops <- {}
        
        // Initialize Halloween drop as nil (will be set later)
        self.halloweenDrop = nil
        
        // Create Admin resource
        self.account.storage.save(<- create Admin(), to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
