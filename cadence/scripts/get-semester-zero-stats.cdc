import SemesterZero from 0xce9dd43888d99574

/// Get total stats for Semester Zero NFTs

access(all) fun main(): {String: UInt64} {
    return SemesterZero.getStats()
}
