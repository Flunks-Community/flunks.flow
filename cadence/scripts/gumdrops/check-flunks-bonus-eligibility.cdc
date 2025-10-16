// Script to check if a user can claim Flunks holder bonus and how much

import GUMDrops from "../../contracts/GUMDrops.cdc"
import Flunks from "../../contracts/Flunks.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

access(all) struct BonusEligibility {
    access(all) let canClaim: Bool
    access(all) let flunksOwned: Int
    access(all) let bonusAmount: UFix64
    access(all) let alreadyClaimed: Bool
    access(all) let reason: String
    
    init(canClaim: Bool, flunksOwned: Int, bonusAmount: UFix64, alreadyClaimed: Bool, reason: String) {
        self.canClaim = canClaim
        self.flunksOwned = flunksOwned
        self.bonusAmount = bonusAmount
        self.alreadyClaimed = alreadyClaimed
        self.reason = reason
    }
}

access(all) fun main(userAddress: Address): BonusEligibility {
    // Get user's account
    let account = getAccount(userAddress)
    
    // Check if they have Flunks collection
    if let collectionCap = account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection) {
        if let collection = collectionCap.borrow() {
            let flunksOwned = collection.getIDs().length
            
            if flunksOwned == 0 {
                return BonusEligibility(
                    canClaim: false,
                    flunksOwned: 0,
                    bonusAmount: 0.0,
                    alreadyClaimed: false,
                    reason: "No Flunks NFTs owned"
                )
            }
            
            // Check if already claimed
            let alreadyClaimed = GUMDrops.hasClaimedFlunksBonus(address: userAddress)
            
            if alreadyClaimed {
                return BonusEligibility(
                    canClaim: false,
                    flunksOwned: flunksOwned,
                    bonusAmount: 0.0,
                    alreadyClaimed: true,
                    reason: "Already claimed Flunks holder bonus"
                )
            }
            
            // Calculate bonus (2 GUM per Flunks)
            let bonusAmount = UFix64(flunksOwned) * 2.0
            
            return BonusEligibility(
                canClaim: true,
                flunksOwned: flunksOwned,
                bonusAmount: bonusAmount,
                alreadyClaimed: false,
                reason: "Eligible to claim!"
            )
        }
    }
    
    return BonusEligibility(
        canClaim: false,
        flunksOwned: 0,
        bonusAmount: 0.0,
        alreadyClaimed: false,
        reason: "Flunks collection not found"
    )
}
