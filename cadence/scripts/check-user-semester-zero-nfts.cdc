import SemesterZero from 0xce9dd43888d99574
import NonFungibleToken from 0x1d7e57aa55817448

/// Check if a user has Semester Zero (Chapter 5) NFTs
/// 
/// Usage:
/// flow scripts execute cadence/scripts/check-user-semester-zero-nfts.cdc 0xADDRESS --network=mainnet

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let account = getAccount(userAddress)
    let result: {String: AnyStruct} = {}
    
    result["address"] = userAddress.toString()
    
    // Check for Chapter 5 Collection
    let collectionRef = account.capabilities
        .get<&{NonFungibleToken.CollectionPublic}>(SemesterZero.Chapter5CollectionPublicPath)
        .borrow()
    
    if collectionRef != nil {
        let nftIDs = collectionRef!.getIDs()
        result["hasCollection"] = true
        result["nftIDs"] = nftIDs
        result["totalNFTs"] = nftIDs.length
    } else {
        result["hasCollection"] = false
        result["nftIDs"] = []
        result["totalNFTs"] = 0
    }
    
    return result
}
