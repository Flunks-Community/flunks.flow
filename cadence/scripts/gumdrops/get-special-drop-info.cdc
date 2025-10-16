// Script to get information about a special drop

import GUMDrops from "../../contracts/GUMDrops.cdc"

access(all) struct SpecialDropInfo {
    access(all) let dropID: UInt64
    access(all) let totalAmount: UFix64
    access(all) let amountPerClaim: UFix64
    access(all) let remainingAmount: UFix64
    access(all) let startTime: UFix64
    access(all) let endTime: UFix64
    access(all) let requiresFlunks: Bool
    access(all) let description: String
    access(all) let isActive: Bool
    access(all) let claimCount: Int
    
    init(
        dropID: UInt64,
        totalAmount: UFix64,
        amountPerClaim: UFix64,
        remainingAmount: UFix64,
        startTime: UFix64,
        endTime: UFix64,
        requiresFlunks: Bool,
        description: String,
        isActive: Bool,
        claimCount: Int
    ) {
        self.dropID = dropID
        self.totalAmount = totalAmount
        self.amountPerClaim = amountPerClaim
        self.remainingAmount = remainingAmount
        self.startTime = startTime
        self.endTime = endTime
        self.requiresFlunks = requiresFlunks
        self.description = description
        self.isActive = isActive
        self.claimCount = claimCount
    }
}

access(all) fun main(dropID: UInt64): SpecialDropInfo? {
    return GUMDrops.getSpecialDropInfo(dropID: dropID)
}
