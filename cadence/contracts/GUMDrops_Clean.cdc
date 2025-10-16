// GUMDrops - Supabase-integrated reward distribution system
// GUM is earned and tracked on the website (Supabase)
// This contract handles on-chain verification and special NFT-gated rewards

import FungibleToken from "./FungibleToken.cdc"
import GUM from "./GUM.cdc"
import Flunks from "./Flunks.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"

access(all)
contract GUMDrops {
    
    // Storage Paths
    access(all) let AdminStoragePath: StoragePath

    // Events - Track on-chain GUM distribution only
    access(all) event GUMWithdrawnFromWebsite(address: Address, amount: UFix64, withdrawalID: String)
    access(all) event FlunksHolderBonusClaimed(address: Address, amount: UFix64, flunksCount: UInt64)
    access(all) event SpecialDropCreated(dropID: UInt64, totalAmount: UFix64, startTime: UFix64, requiresFlunks: Bool)
    access(all) event SpecialDropClaimed(dropID: UInt64, address: Address, amount: UFix64)

    // Constants for on-chain bonuses only
    access(all) let FLUNKS_HOLDER_BONUS: UFix64  // Bonus GUM per Flunks owned (on-chain verification)

    // Special drop tracking (event-based, admin-created drops)
    access(self) var nextDropID: UInt64
    access(self) var specialDrops: @{UInt64: SpecialDrop}

    // Special drop resource (for events, milestones, etc.)
    access(all) resource SpecialDrop {
        access(all) let dropID: UInt64
        access(all) let totalAmount: UFix64
        access(all) let amountPerClaim: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64?
        access(all) let requiresFlunks: Bool
        access(all) let description: String
        access(all) var remainingAmount: UFix64
        access(self) var claimedAddresses: {Address: Bool}

        init(
            dropID: UInt64,
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64?,
            requiresFlunks: Bool,
            description: String
        ) {
            self.dropID = dropID
            self.totalAmount = totalAmount
            self.amountPerClaim = amountPerClaim
            self.startTime = startTime
            self.endTime = endTime
            self.requiresFlunks = requiresFlunks
            self.description = description
            self.remainingAmount = totalAmount
            self.claimedAddresses = {}
        }

        access(all) fun canClaim(address: Address): Bool {
            let currentTime = getCurrentBlock().timestamp
            
            // Check if drop is active
            if currentTime < self.startTime {
                return false
            }
            
            if self.endTime != nil && currentTime > self.endTime! {
                return false
            }
            
            // Check if already claimed
            if self.claimedAddresses[address] == true {
                return false
            }
            
            // Check if enough remaining
            if self.remainingAmount < self.amountPerClaim {
                return false
            }
            
            return true
        }

        access(contract) fun recordClaim(address: Address): UFix64 {
            pre {
                self.canClaim(address: address): "Cannot claim from this drop"
            }
            
            self.claimedAddresses[address] = true
            self.remainingAmount = self.remainingAmount - self.amountPerClaim
            
            return self.amountPerClaim
        }

        access(all) fun getClaimStatus(address: Address): Bool {
            return self.claimedAddresses[address] ?? false
        }
    }

    // Admin resource
    access(all) resource Admin {
        
        // Withdraw GUM from website balance to user's wallet
        // Called by backend when user requests withdrawal from Supabase balance
        access(all) fun withdrawGUMToWallet(
            recipient: Address,
            amount: UFix64,
            withdrawalID: String
        ) {
            // Mint GUM tokens
            let minter = GUMDrops.account.storage.borrow<&GUM.Minter>(from: GUM.AdminStoragePath)
                ?? panic("Could not borrow GUM Minter")
            
            let vault <- minter.mintTokens(amount: amount)
            
            // Send to user's wallet
            let recipientVault = getAccount(recipient).capabilities
                .get<&{FungibleToken.Receiver}>(GUM.VaultReceiverPublicPath)
                .borrow()
                ?? panic("Could not borrow recipient vault")
            
            recipientVault.deposit(from: <- vault)
            
            emit GUMWithdrawnFromWebsite(
                address: recipient,
                amount: amount,
                withdrawalID: withdrawalID
            )
        }
        
        // Create a special event drop
        access(all) fun createSpecialDrop(
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64?,
            requiresFlunks: Bool,
            description: String
        ): UInt64 {
            let dropID = GUMDrops.nextDropID
            let drop <- create SpecialDrop(
                dropID: dropID,
                totalAmount: totalAmount,
                amountPerClaim: amountPerClaim,
                startTime: startTime,
                endTime: endTime,
                requiresFlunks: requiresFlunks,
                description: description
            )
            
            GUMDrops.specialDrops[dropID] <-! drop
            GUMDrops.nextDropID = GUMDrops.nextDropID + 1
            
            emit SpecialDropCreated(
                dropID: dropID,
                totalAmount: totalAmount,
                startTime: startTime,
                requiresFlunks: requiresFlunks
            )
            
            return dropID
        }

        // Remove a special drop
        access(all) fun removeSpecialDrop(dropID: UInt64) {
            destroy GUMDrops.specialDrops.remove(key: dropID)
        }
    }

    // Helper function: Get Flunks count for an address
    access(all) fun getFlunksCount(address: Address): UInt64 {
        let account = getAccount(address)
        let collectionRef = account.capabilities
            .get<&Flunks.Collection>(Flunks.CollectionPublicPath)
            .borrow()
        
        if collectionRef == nil {
            return 0
        }
        
        return UInt64(collectionRef!.getIDs().length)
    }

    // On-chain Flunks holder bonus claim
    // Verifies NFT ownership and mints bonus GUM
    access(all) fun claimFlunksHolderBonus(claimer: auth(Storage, Capabilities) &Account) {
        let flunksCount = self.getFlunksCount(address: claimer.address)
        
        assert(flunksCount > 0, message: "Must own at least one Flunks NFT")
        
        let bonusAmount = UFix64(flunksCount) * self.FLUNKS_HOLDER_BONUS
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: bonusAmount)
        
        emit FlunksHolderBonusClaimed(
            address: claimer.address,
            amount: bonusAmount,
            flunksCount: flunksCount
        )
    }

    // Claim from a special event drop
    access(all) fun claimSpecialDrop(claimer: auth(Storage, Capabilities) &Account, dropID: UInt64) {
        let dropRef = &self.specialDrops[dropID] as &SpecialDrop?
            ?? panic("Drop not found")
        
        // Check if requires Flunks ownership
        if dropRef.requiresFlunks {
            let flunksCount = self.getFlunksCount(address: claimer.address)
            assert(flunksCount > 0, message: "Must own Flunks NFT to claim this drop")
        }
        
        let claimAmount = dropRef.recordClaim(address: claimer.address)
        
        // Mint GUM tokens
        self.mintToUser(address: claimer.address, amount: claimAmount)
        
        emit SpecialDropClaimed(dropID: dropID, address: claimer.address, amount: claimAmount)
    }

    // Internal helper to mint GUM to user
    access(self) fun mintToUser(address: Address, amount: UFix64) {
        let minter = self.account.storage.borrow<&GUM.Minter>(from: GUM.AdminStoragePath)
            ?? panic("Could not borrow GUM Minter")
        
        let vault <- minter.mintTokens(amount: amount)
        
        let recipientVault = getAccount(address).capabilities
            .get<&{FungibleToken.Receiver}>(GUM.VaultReceiverPublicPath)
            .borrow()
            ?? panic("Could not borrow recipient vault")
        
        recipientVault.deposit(from: <- vault)
    }

    // Public view functions
    access(all) fun getSpecialDrop(dropID: UInt64): &SpecialDrop? {
        return &self.specialDrops[dropID] as &SpecialDrop?
    }

    access(all) fun getActiveDropIDs(): [UInt64] {
        let currentTime = getCurrentBlock().timestamp
        let activeDrops: [UInt64] = []
        
        for dropID in self.specialDrops.keys {
            let dropRef = &self.specialDrops[dropID] as &SpecialDrop?
            if dropRef != nil {
                if currentTime >= dropRef!.startTime {
                    if dropRef!.endTime == nil || currentTime <= dropRef!.endTime! {
                        if dropRef!.remainingAmount > 0.0 {
                            activeDrops.append(dropID)
                        }
                    }
                }
            }
        }
        
        return activeDrops
    }

    init() {
        // Set paths
        self.AdminStoragePath = /storage/GUMDropsAdmin

        // Set constants - Only on-chain bonuses
        // Note: Daily check-ins, streaks, and website activities are tracked in Supabase
        self.FLUNKS_HOLDER_BONUS = 2.0  // 2 GUM per Flunks owned (on-chain verification)

        // Initialize special drop tracking
        self.nextDropID = 0
        self.specialDrops <- {}

        // Create and save admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
    }
}
