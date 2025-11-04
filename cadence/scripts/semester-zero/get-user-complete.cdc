import SemesterZero from "../../contracts/SemesterZero.cdc"
import Flunks from "../../contracts/Flunks.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

/// Get complete Semester Zero user info
/// Shows: Profile, GUM, Flunks with dynamic day/night images, Achievements
access(all) fun main(userAddress: Address): UserInfo? {
    
    // Get comprehensive stats (now built into SemesterZero!)
    let stats = SemesterZero.getOwnerStats(ownerAddress: userAddress)
    
    if stats == nil {
        return nil
    }
    
    // Get Flunks with dynamic day/night images
    let account = getAccount(userAddress)
    let flunksCollection = account.capabilities
        .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
        .borrow()
    
    let dynamicFlunks: [FlunksNFTInfo] = []
    
    if let collection = flunksCollection {
        let nftIDs = collection.getIDs()
        
        for nftID in nftIDs {
            if let nftRef = collection.borrowNFT(nftID) {
                // Cast to Flunks NFT to access template
                let flunksNFT = nftRef as! &Flunks.NFT
                let template = flunksNFT.getNFTTemplate()
                let metadata = template.getMetadata()
                
                // Use SemesterZero's built-in dynamic display function!
                let dynamicDisplay = SemesterZero.getFlunksDynamicDisplay(
                    flunksNFTMetadata: metadata,
                    flunksName: template.name,
                    flunksTemplateID: flunksNFT.templateID,
                    ownerAddress: userAddress
                )
                
                dynamicFlunks.append(FlunksNFTInfo(
                    id: flunksNFT.id,
                    templateID: flunksNFT.templateID,
                    serialNumber: flunksNFT.serialNumber,
                    name: dynamicDisplay.name,
                    imageURL: dynamicDisplay.imageURL,
                    timeContext: dynamicDisplay.timeContext,
                    owner: userAddress
                ))
            }
        }
    }
    
    // Get active drops
    let activeDrops = SemesterZero.getActiveDrops()
    
    // Get active airdrops
    let activeAirdrops = SemesterZero.getActiveAirdrops()
    
    // Check eligibility for each airdrop
    let eligibleAirdrops: [UInt64] = []
    for airdrop in activeAirdrops {
        if SemesterZero.checkAirdropEligibility(claimer: userAddress, airdropID: airdrop.airdropID) {
            eligibleAirdrops.append(airdrop.airdropID)
        }
    }
    
    return UserInfo(
        address: stats!.address,
        username: stats!.username,
        bio: stats!.bio,
        avatar: stats!.avatar,
        timezone: stats!.timezone,
        isDaytime: stats!.isDaytime,
        localHour: stats!.localHour,
        gumBalance: stats!.gumBalance,
        gumTotalEarned: stats!.gumTotalEarned,
        gumTotalSpent: stats!.gumTotalSpent,
        gumTotalTransferred: stats!.gumTotalTransferred,
        flunksOwned: stats!.flunksOwned,
        flunks: dynamicFlunks,
        achievementsUnlocked: stats!.achievementsUnlocked,
        accountAge: stats!.accountAge,
        activeDropsCount: activeDrops.length,
        eligibleAirdropsCount: eligibleAirdrops.length,
        eligibleAirdropIDs: eligibleAirdrops
    )
}

access(all) struct FlunksNFTInfo {
    access(all) let id: UInt64
    access(all) let templateID: UInt64
    access(all) let serialNumber: UInt64
    access(all) let name: String
    access(all) let imageURL: String
    access(all) let timeContext: String  // "day", "night", or "default"
    access(all) let owner: Address
    
    init(
        id: UInt64,
        templateID: UInt64,
        serialNumber: UInt64,
        name: String,
        imageURL: String,
        timeContext: String,
        owner: Address
    ) {
        self.id = id
        self.templateID = templateID
        self.serialNumber = serialNumber
        self.name = name
        self.imageURL = imageURL
        self.timeContext = timeContext
        self.owner = owner
    }
}

access(all) struct UserInfo {
    access(all) let address: Address
    access(all) let username: String
    access(all) let bio: String
    access(all) let avatar: String
    access(all) let timezone: Int
    access(all) let isDaytime: Bool
    access(all) let localHour: Int
    access(all) let gumBalance: UFix64
    access(all) let gumTotalEarned: UFix64
    access(all) let gumTotalSpent: UFix64
    access(all) let gumTotalTransferred: UFix64
    access(all) let flunksOwned: Int
    access(all) let flunks: [FlunksNFTInfo]
    access(all) let achievementsUnlocked: Int
    access(all) let accountAge: UFix64
    access(all) let activeDropsCount: Int
    access(all) let eligibleAirdropsCount: Int
    access(all) let eligibleAirdropIDs: [UInt64]
    
    init(
        address: Address,
        username: String,
        bio: String,
        avatar: String,
        timezone: Int,
        isDaytime: Bool,
        localHour: Int,
        gumBalance: UFix64,
        gumTotalEarned: UFix64,
        gumTotalSpent: UFix64,
        gumTotalTransferred: UFix64,
        flunksOwned: Int,
        flunks: [FlunksNFTInfo],
        achievementsUnlocked: Int,
        accountAge: UFix64,
        activeDropsCount: Int,
        eligibleAirdropsCount: Int,
        eligibleAirdropIDs: [UInt64]
    ) {
        self.address = address
        self.username = username
        self.bio = bio
        self.avatar = avatar
        self.timezone = timezone
        self.isDaytime = isDaytime
        self.localHour = localHour
        self.gumBalance = gumBalance
        self.gumTotalEarned = gumTotalEarned
        self.gumTotalSpent = gumTotalSpent
        self.gumTotalTransferred = gumTotalTransferred
        self.flunksOwned = flunksOwned
        self.flunks = flunks
        self.achievementsUnlocked = achievementsUnlocked
        self.accountAge = accountAge
        self.activeDropsCount = activeDropsCount
        self.eligibleAirdropsCount = eligibleAirdropsCount
        self.eligibleAirdropIDs = eligibleAirdropIDs
    }
}
