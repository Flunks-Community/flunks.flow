import SemesterZero from 0xce9dd43888d99574

/// Get all users who completed Chapter 5 (both slacker + overachiever)
/// This queries the on-chain chapter5Completions dictionary

access(all) fun main(): [{String: AnyStruct}] {
    let completions: [{String: AnyStruct}] = []
    
    // Note: We can't iterate over dictionaries directly in Cadence
    // We need to query specific addresses
    
    // Instead, let's get the stats
    let stats = SemesterZero.getStats()
    
    return [{
        "totalCompletions": stats["totalChapter5Completions"]!,
        "totalNFTsMinted": stats["totalChapter5NFTs"]!,
        "note": "To see specific addresses, you need to check them individually with getChapter5Status(address)"
    }]
}
