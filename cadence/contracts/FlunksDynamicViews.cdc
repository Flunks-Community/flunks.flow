import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448
import Flunks from "./Flunks.cdc"
import SemesterZero from "./SemesterZero.cdc"

/// FlunksDynamicViews - Enhances Flunks NFTs with time-based dynamic metadata
/// Wraps existing Flunks contract to add day/night imagery based on user timezone
access(all) contract FlunksDynamicViews {
    
    // ========================================
    // ENHANCED METADATA VIEW
    // ========================================
    
    /// Get Flunks NFT metadata with dynamic day/night imagery
    /// based on the owner's timezone from their SemesterZero profile
    access(all) fun getDynamicDisplay(
        flunksNFT: &Flunks.NFT,
        ownerAddress: Address
    ): MetadataViews.Display {
        
        // Get base metadata from Flunks NFT
        let template = flunksNFT.getNFTTemplate()
        let metadata = template.getMetadata()
        
        // Try to get owner's timezone profile
        let account = getAccount(ownerAddress)
        let profileRef = account.capabilities
            .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
            .borrow()
        
        // Determine which image to show
        var imageURL = metadata["uri"] ?? ""
        
        if let profile = profileRef {
            let isDaytime = profile.isDaytime()
            
            // Check if this Flunks has day/night variants
            if metadata["dayImageUri"] != nil && metadata["nightImageUri"] != nil {
                imageURL = isDaytime ? metadata["dayImageUri"]! : metadata["nightImageUri"]!
            }
        }
        
        return MetadataViews.Display(
            name: template.name.concat(" #").concat(flunksNFT.templateID.toString()),
            description: template.description,
            thumbnail: MetadataViews.HTTPFile(url: imageURL)
        )
    }
    
    /// Get comprehensive stats for a Flunks owner (for profile display)
    access(all) fun getOwnerStats(ownerAddress: Address): OwnerStats? {
        let account = getAccount(ownerAddress)
        
        // Get Flunks count
        let flunksCollection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
            .borrow()
        let flunksCount = flunksCollection?.getIDs().length ?? 0
        
        // Get GUM info
        let gumAccount = account.capabilities
            .get<&{SemesterZero.GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
            .borrow()
        let gumInfo = gumAccount?.getInfo()
        
        // Get Profile info
        let profile = account.capabilities
            .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
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
    
    /// Get all Flunks owned by an address with dynamic metadata
    access(all) fun getAllFlunksDynamic(ownerAddress: Address): [FlunksNFTInfo] {
        let account = getAccount(ownerAddress)
        let flunksCollection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
            .borrow()
            ?? panic("Could not borrow Flunks collection")
        
        let nftIDs = flunksCollection.getIDs()
        let results: [FlunksNFTInfo] = []
        
        for nftID in nftIDs {
            if let nft = flunksCollection.borrowNFT(nftID) {
                let flunksNFT = nft as! &Flunks.NFT
                let display = self.getDynamicDisplay(flunksNFT: flunksNFT, ownerAddress: ownerAddress)
                
                results.append(FlunksNFTInfo(
                    id: flunksNFT.id,
                    templateID: flunksNFT.templateID,
                    serialNumber: flunksNFT.serialNumber,
                    name: display.name,
                    description: display.description,
                    imageURL: display.thumbnail.uri(),
                    owner: ownerAddress
                ))
            }
        }
        
        return results
    }
    
    access(all) struct FlunksNFTInfo {
        access(all) let id: UInt64
        access(all) let templateID: UInt64
        access(all) let serialNumber: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let imageURL: String
        access(all) let owner: Address
        
        init(
            id: UInt64,
            templateID: UInt64,
            serialNumber: UInt64,
            name: String,
            description: String,
            imageURL: String,
            owner: Address
        ) {
            self.id = id
            self.templateID = templateID
            self.serialNumber = serialNumber
            self.name = name
            self.description = description
            self.imageURL = imageURL
            self.owner = owner
        }
    }
    
    init() {}
}
