// GumDrops Hybrid Contract
// 
// GUM is NOT a token - it's tracked points that can be:
// 1. Earned on website (Supabase) - FREE, instant
// 2. Transferred on-chain (here) - Verifiable, transparent
// 3. Spent on special drops (here) - NFT-gated, limited-time
//
// This is like a "GUM ledger" - tracks balances but NOT a fungible token

import NonFungibleToken from "./NonFungibleToken.cdc"
import Flunks from "./Flunks.cdc"

access(all) contract GumDropsHybrid {
    
    // ========================================
    // Paths
    // ========================================
    
    access(all) let GumAccountStoragePath: StoragePath
    access(all) let GumAccountPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // ========================================
    // Events
    // ========================================
    
    access(all) event GumTransferred(from: Address, to: Address, amount: UFix64, message: String?)
    access(all) event GumSpent(address: Address, amount: UFix64, reason: String, metadata: {String: String})
    access(all) event GumAwarded(address: Address, amount: UFix64, source: String)
    access(all) event SpecialDropCreated(dropID: UInt64, totalAmount: UFix64, description: String)
    access(all) event SpecialDropClaimed(dropID: UInt64, claimer: Address, amount: UFix64)
    access(all) event GumSynced(address: Address, newBalance: UFix64, source: String)
    
    // ========================================
    // Contract State
    // ========================================
    
    access(all) var totalGumTracked: UFix64
    access(all) var totalTransfers: UInt64
    access(all) var totalDropsClaimed: UInt64
    
    // Special drops storage
    access(contract) let specialDrops: @{UInt64: SpecialDrop}
    access(all) var nextDropID: UInt64
    
    // ========================================
    // GUM Account (User's on-chain GUM tracking)
    // ========================================
    
    access(all) resource GumAccount {
        // On-chain balance (synced from Supabase or earned on-chain)
        access(all) var balance: UFix64
        
        // Track history
        access(all) var totalEarned: UFix64
        access(all) var totalSpent: UFix64
        access(all) var totalTransferred: UFix64
        access(all) var lastSyncTimestamp: UFix64
        
        init() {
            self.balance = 0.0
            self.totalEarned = 0.0
            self.totalSpent = 0.0
            self.totalTransferred = 0.0
            self.lastSyncTimestamp = getCurrentBlock().timestamp
        }
        
        // Sync balance from Supabase (admin function)
        access(contract) fun syncBalance(newBalance: UFix64) {
            self.balance = newBalance
            self.lastSyncTimestamp = getCurrentBlock().timestamp
        }
        
        // Transfer GUM to another user (on-chain)
        access(all) fun transfer(amount: UFix64, to: Address, message: String?) {
            pre {
                self.balance >= amount: "Insufficient GUM balance"
                amount > 0.0: "Amount must be positive"
            }
            
            self.balance = self.balance - amount
            self.totalTransferred = self.totalTransferred + amount
            
            // Get recipient's account
            let recipient = getAccount(to)
            let recipientRef = recipient.capabilities.get<&GumAccount>(GumDropsHybrid.GumAccountPublicPath)
                .borrow()
                ?? panic("Recipient doesn't have GUM account setup")
            
            recipientRef.deposit(amount: amount, source: "transfer_in")
            
            emit GumTransferred(from: self.owner!.address, to: to, amount: amount, message: message)
        }
        
        // Deposit GUM (from transfer or admin)
        access(contract) fun deposit(amount: UFix64, source: String) {
            self.balance = self.balance + amount
            self.totalEarned = self.totalEarned + amount
            
            emit GumAwarded(address: self.owner!.address, amount: amount, source: source)
        }
        
        // Spend GUM (internal use)
        access(contract) fun spend(amount: UFix64, reason: String, metadata: {String: String}) {
            pre {
                self.balance >= amount: "Insufficient GUM balance"
            }
            
            self.balance = self.balance - amount
            self.totalSpent = self.totalSpent + amount
            
            emit GumSpent(address: self.owner!.address, amount: amount, reason: reason, metadata: metadata)
        }
        
        // Get balance info
        access(all) fun getInfo(): GumAccountInfo {
            return GumAccountInfo(
                balance: self.balance,
                totalEarned: self.totalEarned,
                totalSpent: self.totalSpent,
                totalTransferred: self.totalTransferred,
                lastSyncTimestamp: self.lastSyncTimestamp
            )
        }
    }
    
    // Public interface for GumAccount
    access(all) resource interface GumAccountPublic {
        access(all) fun getInfo(): GumAccountInfo
        access(all) fun transfer(amount: UFix64, to: Address, message: String?)
    }
    
    // ========================================
    // Special Drop (Limited-time GUM airdrops)
    // ========================================
    
    access(all) resource SpecialDrop {
        access(all) let dropID: UInt64
        access(all) let totalAmount: UFix64
        access(all) let amountPerClaim: UFix64
        access(all) var remainingAmount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let requiresFlunks: Bool
        access(all) let description: String
        
        // Track who claimed
        access(contract) let claimers: {Address: Bool}
        
        init(
            dropID: UInt64,
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64,
            requiresFlunks: Bool,
            description: String
        ) {
            self.dropID = dropID
            self.totalAmount = totalAmount
            self.amountPerClaim = amountPerClaim
            self.remainingAmount = totalAmount
            self.startTime = startTime
            self.endTime = endTime
            self.requiresFlunks = requiresFlunks
            self.description = description
            self.claimers = {}
        }
        
        access(contract) fun claim(claimer: Address, hasFlunks: Bool): UFix64 {
            pre {
                getCurrentBlock().timestamp >= self.startTime: "Drop hasn't started yet"
                getCurrentBlock().timestamp <= self.endTime: "Drop has ended"
                self.remainingAmount >= self.amountPerClaim: "Drop is depleted"
                self.claimers[claimer] == nil: "Already claimed this drop"
                !self.requiresFlunks || hasFlunks: "Requires Flunks NFT ownership"
            }
            
            self.claimers[claimer] = true
            self.remainingAmount = self.remainingAmount - self.amountPerClaim
            
            return self.amountPerClaim
        }
        
        access(all) fun getInfo(): SpecialDropInfo {
            return SpecialDropInfo(
                dropID: self.dropID,
                totalAmount: self.totalAmount,
                amountPerClaim: self.amountPerClaim,
                remainingAmount: self.remainingAmount,
                startTime: self.startTime,
                endTime: self.endTime,
                requiresFlunks: self.requiresFlunks,
                description: self.description,
                isActive: getCurrentBlock().timestamp >= self.startTime && getCurrentBlock().timestamp <= self.endTime,
                claimCount: self.claimers.length
            )
        }
        
        access(all) fun hasClaimed(address: Address): Bool {
            return self.claimers[address] != nil
        }
    }
    
    // ========================================
    // Admin (Create drops, sync balances)
    // ========================================
    
    access(all) resource Admin {
        
        // Sync user's GUM balance from Supabase to blockchain
        access(all) fun syncUserBalance(userAddress: Address, supabaseBalance: UFix64) {
            let account = getAccount(userAddress)
            let accountRef = account.capabilities.get<&GumAccount>(GumDropsHybrid.GumAccountPublicPath)
                .borrow()
                ?? panic("User doesn't have GUM account")
            
            accountRef.syncBalance(newBalance: supabaseBalance)
            
            emit GumSynced(address: userAddress, newBalance: supabaseBalance, source: "supabase_sync")
        }
        
        // Award GUM directly (for special cases)
        access(all) fun awardGum(to: Address, amount: UFix64, source: String) {
            let recipient = getAccount(to)
            let recipientRef = recipient.capabilities.get<&GumAccount>(GumDropsHybrid.GumAccountPublicPath)
                .borrow()
                ?? panic("Recipient doesn't have GUM account")
            
            recipientRef.deposit(amount: amount, source: source)
            GumDropsHybrid.totalGumTracked = GumDropsHybrid.totalGumTracked + amount
        }
        
        // Create special drop
        access(all) fun createSpecialDrop(
            totalAmount: UFix64,
            amountPerClaim: UFix64,
            startTime: UFix64,
            endTime: UFix64,
            requiresFlunks: Bool,
            description: String
        ): UInt64 {
            let dropID = GumDropsHybrid.nextDropID
            GumDropsHybrid.nextDropID = dropID + 1
            
            let drop <- create SpecialDrop(
                dropID: dropID,
                totalAmount: totalAmount,
                amountPerClaim: amountPerClaim,
                startTime: startTime,
                endTime: endTime,
                requiresFlunks: requiresFlunks,
                description: description
            )
            
            emit SpecialDropCreated(dropID: dropID, totalAmount: totalAmount, description: description)
            
            GumDropsHybrid.specialDrops[dropID] <-! drop
            
            return dropID
        }
    }
    
    // ========================================
    // Structs (Read-only info)
    // ========================================
    
    access(all) struct GumAccountInfo {
        access(all) let balance: UFix64
        access(all) let totalEarned: UFix64
        access(all) let totalSpent: UFix64
        access(all) let totalTransferred: UFix64
        access(all) let lastSyncTimestamp: UFix64
        
        init(
            balance: UFix64,
            totalEarned: UFix64,
            totalSpent: UFix64,
            totalTransferred: UFix64,
            lastSyncTimestamp: UFix64
        ) {
            self.balance = balance
            self.totalEarned = totalEarned
            self.totalSpent = totalSpent
            self.totalTransferred = totalTransferred
            self.lastSyncTimestamp = lastSyncTimestamp
        }
    }
    
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
    
    // ========================================
    // Public Functions
    // ========================================
    
    // Create GUM account for new user
    access(all) fun createGumAccount(): @GumAccount {
        return <- create GumAccount()
    }
    
    // Claim from special drop
    access(all) fun claimSpecialDrop(dropID: UInt64, claimer: &GumAccount, flunksCollection: &{NonFungibleToken.CollectionPublic}?) {
        let dropRef = &GumDropsHybrid.specialDrops[dropID] as &SpecialDrop?
            ?? panic("Drop not found")
        
        // Check if user has Flunks if required
        let hasFlunks = flunksCollection != nil && flunksCollection!.getIDs().length > 0
        
        let amount = dropRef.claim(claimer: claimer.owner!.address, hasFlunks: hasFlunks)
        
        claimer.deposit(amount: amount, source: "special_drop_".concat(dropID.toString()))
        
        GumDropsHybrid.totalGumTracked = GumDropsHybrid.totalGumTracked + amount
        GumDropsHybrid.totalDropsClaimed = GumDropsHybrid.totalDropsClaimed + 1
        
        emit SpecialDropClaimed(dropID: dropID, claimer: claimer.owner!.address, amount: amount)
    }
    
    // Get drop info
    access(all) fun getSpecialDropInfo(dropID: UInt64): SpecialDropInfo? {
        if let dropRef = &GumDropsHybrid.specialDrops[dropID] as &SpecialDrop? {
            return dropRef.getInfo()
        }
        return nil
    }
    
    // Get all active drops
    access(all) fun getActiveDrops(): [SpecialDropInfo] {
        let activeDrops: [SpecialDropInfo] = []
        let currentTime = getCurrentBlock().timestamp
        
        for dropID in self.specialDrops.keys {
            if let dropRef = &self.specialDrops[dropID] as &SpecialDrop? {
                let info = dropRef.getInfo()
                if info.isActive {
                    activeDrops.append(info)
                }
            }
        }
        
        return activeDrops
    }
    
    // ========================================
    // Contract Init
    // ========================================
    
    init() {
        self.GumAccountStoragePath = /storage/GumDropsHybridAccount
        self.GumAccountPublicPath = /public/GumDropsHybridAccount
        self.AdminStoragePath = /storage/GumDropsHybridAdmin
        
        self.totalGumTracked = 0.0
        self.totalTransfers = 0
        self.totalDropsClaimed = 0
        
        self.specialDrops <- {}
        self.nextDropID = 1
        
        // Create admin resource
        self.account.storage.save(<- create Admin(), to: self.AdminStoragePath)
    }
}
