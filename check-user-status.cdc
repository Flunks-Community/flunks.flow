import SemesterZero from 0xce9dd43888d99574

/// Check user's Chapter 5 completion status and GumDrop eligibility
access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let result: {String: AnyStruct} = {}
    
    // Check if user has a profile (means they've claimed before)
    let account = getAccount(userAddress)
    let profileCap = account.capabilities
        .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
        .borrow()
    
    if profileCap != nil {
        result["hasProfile"] = true
        result["username"] = profileCap!.username
        result["timezone"] = profileCap!.timezone
    } else {
        result["hasProfile"] = false
    }
    
    // Check Chapter 5 completion status
    let completionStatus = SemesterZero.chapter5Completions[userAddress]
    if completionStatus != nil {
        result["slackerComplete"] = completionStatus!.slackerComplete
        result["overachieverComplete"] = completionStatus!.overachieverComplete
        result["fullyComplete"] = completionStatus!.isFullyComplete()
        result["nftAirdropped"] = completionStatus!.nftAirdropped
        if completionStatus!.nftAirdropped {
            result["nftID"] = completionStatus!.nftID
        }
    } else {
        result["chapter5Status"] = "Not started"
    }
    
    // Check if eligible for Chapter 5 NFT
    result["eligibleForNFT"] = SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress)
    
    // Check if they have Chapter 5 collection
    let collectionCap = account.capabilities
        .get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
        .borrow()
    
    result["hasChapter5Collection"] = collectionCap != nil
    if collectionCap != nil {
        result["nftsInCollection"] = collectionCap!.getIDs()
    }
    
    // Check active GumDrop
    if SemesterZero.activeGumDrop != nil {
        result["activeGumDrop"] = true
        result["gumDropId"] = SemesterZero.activeGumDrop!.dropId
        result["gumDropEndTime"] = SemesterZero.activeGumDrop!.endTime
        result["currentTime"] = getCurrentBlock().timestamp
    } else {
        result["activeGumDrop"] = false
    }
    
    return result
}
