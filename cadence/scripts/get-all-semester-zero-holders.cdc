import FlunksSemesterZero from 0xce9dd43888d99574
import SemesterZero from 0xce9dd43888d99574
import NonFungibleToken from 0x1d7e57aa55817448

/// Get all Chapter 5 NFT holders and their NFT IDs
/// This queries the SemesterZero contract for Chapter5NFTs (wrapped by FlunksSemesterZero)
///
/// Returns a dictionary: {Address: [NFT IDs]}

access(all) fun main(): {Address: [UInt64]} {
    let holders: {Address: [UInt64]} = {}
    
    // Get the stats to see total minted
    let stats = SemesterZero.getStats()
    log("Total Chapter 5 NFTs minted: ".concat(stats["totalChapter5NFTs"]!.toString()))
    
    // Note: To get all holders, you'd need to track Deposit events
    // or maintain an on-chain registry. This is a simplified version
    // that shows the approach.
    
    return holders
}
