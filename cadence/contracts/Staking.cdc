

// SPDX-License-Identifier: MIT
import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import Flunks from "./Flunks.cdc"
import Backpack from "./Backpack.cdc"
import GUM from "./GUM.cdc"
import HybridCustodyHelper from "./HybridCustodyHelper.cdc"
import GUMStakingTracker from "./GUMStakingTracker.cdc"

access(all)
contract Staking{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var Pools: @{String: Pool} // {poolName: Pool}
	
	
	access(all)
	event Stake(id: UInt64, pool: String)
	
	access(all)
	event Unstake(id: UInt64, pool: String)
	
	access(all)
	event ClaimReward(pool: String, amount: UFix64, tokenID: UInt64)
	
	access(all)
	resource Pool{ 
		access(all)
		let name: String
		
		access(all)
		var multiplier: UFix64
		
		access(self)
		var stakedInfo:{ UInt64: StakingInfo} // {tokenID: StakingInfo}
		
		
		access(all)
		fun getStakedInfoByTokenID(tokenID: UInt64): StakingInfo?{ 
			return self.stakedInfo[tokenID]
		}
		
		access(all)
		fun mutateStakingInfo(tokenID: UInt64, stakingInfo: StakingInfo?){ 
			if stakingInfo == nil{ 
				// If new staking info is nil, remove the existing info
				self.stakedInfo.remove(key: tokenID)
				return
			} else{ 
				// Otherwise update the existing info
				self.stakedInfo[tokenID] = stakingInfo
			}
		}
		
		// Admin function to claim GUMS on behalf of users, GUM will go to the staker's wallet if it's still the owner at the time called
		access(contract)
		fun adminClaimOne(tokenID: UInt64, staker: Address){ 
			if !self.stakedInfo.keys.contains(tokenID){ 
				// 1. Not staked, return directly
				return
			}
			let stakingInfo = self.stakedInfo[tokenID]
			if stakingInfo == nil{ 
				// 2. Not staked, return directly
				return
			}
			if (stakingInfo!).staker != staker{ 
				// 3. Staker not owner of the token
				return
			}
			
			// Verify the staker still ownes the token, return silently if not
			if self.name == "Flunks"{ 
				let ownedTokenIDs = HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: staker)
				if !ownedTokenIDs.contains(tokenID){ 
					return
				}
			} else if self.name == "Backpack"{ 
				let ownedTokenIDs = HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: staker)
				if !ownedTokenIDs.contains(tokenID){ 
					return
				}
			}
			
			// Consolidate Rewards
			let validRewardPeriodInDays = (stakingInfo!).validRewardPeriodInDays()
			if validRewardPeriodInDays <= 0.0{ 
				// 4. No reward to claim, return directly
				return
			}
			var stakingReward =
				Staking.pendingRewards(pool: self.name, ownerAddress: staker, tokenID: tokenID)
			let GUMMinter =
				Staking.account.storage.borrow<&GUM.Minter>(from: GUM.AdminStoragePath)
				?? panic("Could not borrow reference to the GUM Minter resource")
			
			// Reset staking timestamp to the last reward timestamp
			let newStakingInfo =
				StakingInfo(
					_staker: (stakingInfo!).staker,
					_tokenID: (stakingInfo!).tokenID,
					_stakedAtInSeconds: UInt64(getCurrentBlock().timestamp) + 60,
					_pool: (stakingInfo!).pool
				)
			self.stakedInfo[tokenID] = newStakingInfo
			emit ClaimReward(
				pool: newStakingInfo.pool,
				amount: stakingReward,
				tokenID: newStakingInfo.tokenID
			)
			Staking.updateTracker(pool: self.name, tokenID: tokenID, amount: stakingReward)
			
			// Mint the specified amount of GUM tokens
			let newVault <- GUMMinter.mintTokens(amount: stakingReward)
			// Deposit the minted tokens into the recipient's Vault
			let recipientVault =
				getAccount(staker).capabilities.get<&{FungibleToken.Receiver}>(
					GUM.VaultReceiverPublicPath
				).borrow()
				?? panic("Could not borrow reference to the recipient's Vault")
			recipientVault.deposit(from: <-newVault)
		}
		
		access(contract)
		fun adminClaimAll(tokenIDs: [UInt64], staker: Address){ 
			for tokenID in tokenIDs{ 
				self.adminClaimOne(tokenID: tokenID, staker: staker)
			}
		}
		
		access(all)
		fun claimOne(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, tokenID: UInt64){ 
			if !self.stakedInfo.keys.contains(tokenID){ 
				// 1. Not staked, return directly
				return
			}
			let stakingInfo = self.stakedInfo[tokenID]
			if stakingInfo == nil{ 
				// 2. Not staked, return directly
				return
			}
			if (stakingInfo!).staker != signerAuth.address{ 
				// 3. staker is not owner, check if the signer is the new owner of the staked NFT
				if self.name == "Flunks"{ 
					let ownedTokenIDs = HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
					if !ownedTokenIDs.contains(tokenID){ 
						return
					}
				} else if self.name == "Backpack"{ 
					let ownedTokenIDs = HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
					if !ownedTokenIDs.contains(tokenID){ 
						return
					}
				}
				
				// if not, return directly
				return
			}
			
			// Consolidate Rewards
			let validRewardPeriodInDays = (stakingInfo!).validRewardPeriodInDays()
			if validRewardPeriodInDays <= 0.0{ 
				// 4. No reward to claim, return directly
				return
			}
			
			// Setup $GUM Vault if user does not already have one
			Staking.setupGUMVault(signer: signerAuth)
			let recipient = getAccount(signerAuth.address)
			let recipientVault =
				signerAuth.capabilities.get<&{FungibleToken.Receiver}>(
					GUM.VaultReceiverPublicPath
				).borrow() ?? panic("Could not borrow reference to the recipient's Vault")
			var stakingReward =
				Staking.pendingRewards(
					pool: self.name,
					ownerAddress: signerAuth.address,
					tokenID: tokenID
				)
			let GUMMinter =
				Staking.account.storage.borrow<&GUM.Minter>(from: GUM.AdminStoragePath)
				?? panic("Could not borrow reference to the GUM Minter resource")
			
			// Reset staking timestamp to the last reward timestamp
			let newStakingInfo =
				StakingInfo(
					_staker: (stakingInfo!).staker,
					_tokenID: (stakingInfo!).tokenID,
					_stakedAtInSeconds: UInt64(getCurrentBlock().timestamp) + 60,
					_pool: (stakingInfo!).pool
				)
			self.stakedInfo[tokenID] = newStakingInfo
			emit ClaimReward(
				pool: newStakingInfo.pool,
				amount: stakingReward,
				tokenID: newStakingInfo.tokenID
			)
			Staking.updateTracker(pool: self.name, tokenID: tokenID, amount: stakingReward)
			
			// Mint the specified amount of GUM tokens
			let newVault <- GUMMinter.mintTokens(amount: stakingReward)
			// Deposit the minted tokens into the recipient's Vault
			recipientVault.deposit(from: <-newVault)
		}
		
		access(all)
		fun claimAll(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, tokenIDs: [UInt64]){ 
			// Force re-link collections
			HybridCustodyHelper.forceRelinkCollections(signer: signerAuth)
			for tokenID in tokenIDs{ 
				self.claimOne(signerAuth: signerAuth, tokenID: tokenID)
			}
		}
		
		access(all)
		fun claimMany(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, tokenIDs: [UInt64]){ 
			// Force re-link collections
			HybridCustodyHelper.forceRelinkCollections(signer: signerAuth)
			for tokenID in tokenIDs{ 
				self.claimOne(signerAuth: signerAuth, tokenID: tokenID)
			}
		}
		
		init(_name: String, _multiplier: UFix64){ 
			self.name = _name
			self.multiplier = _multiplier
			self.stakedInfo ={} 
		}
	}
	
	access(all)
	struct StakingInfo{ 
		access(all)
		let staker: Address
		
		access(all)
		let tokenID: UInt64
		
		access(all)
		let stakedAtInSeconds: UInt64
		
		access(all)
		let pool: String
		
		access(all)
		fun validRewardPeriodInDays(): UFix64{ 
			if UInt64(getCurrentBlock().timestamp) <= self.stakedAtInSeconds{ 
				return 0.0
			}
			
			// Calculate the time difference in seconds
			let timeDiffInSeconds = UInt64(getCurrentBlock().timestamp) - self.stakedAtInSeconds
			
			// Convert the time difference to UFix64 for decimal calculation
			let timeDiffInSecondsDecimal = UFix64(timeDiffInSeconds)
			
			// Number of seconds in a day (as UFix64 for decimal precision)
			let secondsInADay = 86400.0
			
			// Calculate the time difference in days as a decimal
			let daysDecimal = timeDiffInSecondsDecimal / secondsInADay
			return daysDecimal
		}
		
		init(_staker: Address, _tokenID: UInt64, _stakedAtInSeconds: UInt64, _pool: String){ 
			self.staker = _staker
			self.tokenID = _tokenID
			self.stakedAtInSeconds = _stakedAtInSeconds
			self.pool = _pool
		}
	}
	
	// Dumb helper
	access(all)
	fun validateFlunkOwner(ownerAddress: Address, tokenID: UInt64): Bool{ 
		let tokenIDs =
			HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: ownerAddress)
		return tokenIDs.contains(tokenID)
	}
	
	// Dumb helper
	access(all)
	fun validateBackpackOwner(ownerAddress: Address, tokenID: UInt64): Bool{ 
		let tokenIDs =
			HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: ownerAddress)
		return tokenIDs.contains(tokenID)
	}
	
	// Dumb helper
	access(all)
	fun validateOwnership(pool: String, ownerAddress: Address, tokenID: UInt64): Bool{ 
		if pool == "Flunks"{ 
			return Staking.validateFlunkOwner(ownerAddress: ownerAddress, tokenID: tokenID)
		} else if pool == "Backpack"{ 
			return Staking.validateBackpackOwner(ownerAddress: ownerAddress, tokenID: tokenID)
		}
		return false
	}
	
	// Dumb helper
	access(all)
	fun getStakingInfo(
		signerAddress: Address,
		pool: String,
		tokenID: UInt64
	): Staking.StakingInfo?{ 
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let pool = selfAdmin.borrowPool(pool: pool)
		return pool.getStakedInfoByTokenID(tokenID: tokenID)
	}
	
	access(all)
	fun stakeOne(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, pool: String, tokenID: UInt64){ 
		let isValid = Staking.validateOwnership(pool: pool, ownerAddress: signerAuth.address, tokenID: tokenID)
		if (!isValid){ 
			panic("Not owner")
		}

		let existingStakingInfo =
			Staking.getStakingInfo(signerAddress: signerAuth.address, pool: pool, tokenID: tokenID)
		if existingStakingInfo != nil && (existingStakingInfo!).staker == signerAuth.address{ 
			// Already staked by the user, just return silently
			return
		}
		
		// Otherwise stake it fresh
		let stakingInfo =
			StakingInfo(
				_staker: signerAuth.address,
				_tokenID: tokenID,
				_stakedAtInSeconds: UInt64(getCurrentBlock().timestamp) + 60,
				_pool: pool
			)
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef = selfAdmin.borrowPool(pool: pool)
		poolRef.mutateStakingInfo(tokenID: tokenID, stakingInfo: stakingInfo)
		emit Stake(id: tokenID, pool: pool)
	}
	
	access(all)
	fun unstakeOne(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, pool: String, tokenID: UInt64){ 
		let isValid = Staking.validateOwnership(pool: pool, ownerAddress: signerAuth.address, tokenID: tokenID)
		if (!isValid){ 
			panic("Not owner")
		}

		let existingStakingInfo =
			Staking.getStakingInfo(signerAddress: signerAuth.address, pool: pool, tokenID: tokenID)
		if existingStakingInfo == nil{ 
			// Not staked, return silently
			return
		}
		
		// Claim the rewards for the user before unstaking
		Staking.claimOne(signerAuth: signerAuth, pool: pool, tokenID: tokenID)
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef = selfAdmin.borrowPool(pool: pool)
		poolRef.mutateStakingInfo(tokenID: tokenID, stakingInfo: nil)
		emit Unstake(id: tokenID, pool: pool)
	}
	
	access(all)
	fun stakeAll(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account){ 
		let flunksTokenIDs =
			HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(
				ownerAddress: signerAuth.address
			)
		let backpackTokenIDs =
			HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(
				ownerAddress: signerAuth.address
			)
		if flunksTokenIDs != nil{ 
			for tokenID in flunksTokenIDs!{ 
				Staking.stakeOne(signerAuth: signerAuth, pool: "Flunks", tokenID: tokenID)
			}
		}
		if backpackTokenIDs != nil{ 
			for tokenID in backpackTokenIDs!{ 
				Staking.stakeOne(signerAuth: signerAuth, pool: "Backpack", tokenID: tokenID)
			}
		}
	}
	
	access(all)
	fun stakeMany(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, pool: String, tokenIDs: [UInt64]){ 
		for tokenID in tokenIDs{ 
			Staking.stakeOne(signerAuth: signerAuth, pool: pool, tokenID: tokenID)
		}
	}
	
	access(all)
	fun claimOne(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, pool: String, tokenID: UInt64){ 
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef = selfAdmin.borrowPool(pool: pool)
		if pool == "Flunks"{ 
			let flunksTokenIDs = HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
			if !flunksTokenIDs.contains(tokenID){ 
				panic("tokenID not found in signer's collection")
			}
		} else if pool == "Backpack"{ 
			let backpackTokenIDs = HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
			if !backpackTokenIDs.contains(tokenID){ 
				panic("tokenID not found in signer's collection")
			}
		}
		poolRef.claimOne(signerAuth: signerAuth, tokenID: tokenID)
	}
	
	access(all)
	fun claimPool(pool: String, signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account){ 
		// Claim all GUMS accumulated from a pool
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef: &Staking.Pool = selfAdmin.borrowPool(pool: pool)
		if pool == "Flunks"{ 
			let flunksTokenIDs = HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
			poolRef.claimAll(signerAuth: signerAuth, tokenIDs: flunksTokenIDs)
		} else if pool == "Backpack"{ 
			let backpackTokenIDs = HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: signerAuth.address)
			poolRef.claimAll(signerAuth: signerAuth, tokenIDs: backpackTokenIDs)
		}
	}
	
	access(all)
	fun claimMany(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, pool: String, tokenIDs: [UInt64]){ 
		// Claim GUMs from many NFTs accumulated from a pool
		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef: &Staking.Pool = selfAdmin.borrowPool(pool: pool)
		poolRef.claimMany(signerAuth: signerAuth, tokenIDs: tokenIDs)
	}
	
	access(all)
	fun claimAll(signerAuth: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account){ 
		Staking.claimPool(pool: "Flunks", signerAuth: signerAuth)
		Staking.claimPool(pool: "Backpack", signerAuth: signerAuth)
	}
	
	access(all)
	fun pendingRewards(pool: String, ownerAddress: Address, tokenID: UInt64): UFix64{ 
		if !["Flunks", "Backpack"].contains(pool) {
			panic("Invalid pool")
		}

		let selfAdmin =
			self.account.storage.borrow<&Staking.Admin>(from: Staking.AdminStoragePath)
			?? panic("Could not borrow a reference to the NonFungibleGUM Admin")
		let poolRef = selfAdmin.borrowPool(pool: pool)
		let stakingInfo = poolRef.getStakedInfoByTokenID(tokenID: tokenID)
		let stakingPeriodInDays = stakingInfo?.validRewardPeriodInDays() ?? 0.0
		if pool == "Flunks"{ 
			// Flunks staking reward = 5.0 * stakingPeriodInDays
			return poolRef.multiplier * stakingPeriodInDays
		} else if pool == "Backpack"{ 
			// Backpack staking reward = (1.0 + 0.1 * slot bonus)  * stakingPeriodInDays
			let slots = HybridCustodyHelper.getBackpackSlots(ownerAddress: ownerAddress, tokenID: tokenID)
			
			// Invalid slot bonus, throw error
			if slots < 0 || slots > 20{ 
				panic("Invalid slot bonus found!")
			}
			
			// Get slots from MetadataViews resolved traits
			return poolRef.multiplier * stakingPeriodInDays + 0.1 * UFix64(slots) * stakingPeriodInDays
		}
		return poolRef.multiplier * stakingPeriodInDays
	}
	
	access(all)
	fun pendingRewardsPerWallet(address: Address): UFix64{ 
		let flunksTokenIDs =
			HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: address)
		let backpackTokenIDs =
			HybridCustodyHelper.getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: address)
		var totalRewards = 0.0
		if flunksTokenIDs != nil{ 
			for tokenID in flunksTokenIDs{ 
				let pendingRewards = Staking.pendingRewards(pool: "Flunks", ownerAddress: address, tokenID: tokenID)
				totalRewards = totalRewards + pendingRewards
			}
		}
		if backpackTokenIDs != nil{ 
			for tokenID in backpackTokenIDs{ 
				let pendingRewards = Staking.pendingRewards(pool: "Backpack", ownerAddress: address, tokenID: tokenID)
				totalRewards = totalRewards + pendingRewards
			}
		}
		return totalRewards
	}
	
	access(all)
	fun setupGUMVault(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account){ 
		// Check if the account already has a GUM Vault
		if signer.storage.borrow<&GUM.Vault>(from: GUM.VaultStoragePath) == nil{ 
			// If not, create a new empty Vault and save it in the account's storage
			let newVault <- GUM.createEmptyVault(vaultType: Type<@GUM.Vault>())
			signer.storage.save(<-newVault, to: GUM.VaultStoragePath)

			let cap = signer.capabilities.storage.issue<&GUM.Vault>(GUM.VaultStoragePath)
            signer.capabilities.publish(cap, at: GUM.VaultReceiverPublicPath)
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun borrowPool(pool: String): &Pool{ 
			pre{ 
				Staking.Pools[pool] != nil:
					"Cannot borrow Pool: Pool with provided name does not exist"
			}
			return (&Staking.Pools[pool] as &Pool?)!
		}
		
		access(all)
		fun adminClaimPool(pool: String, staker: Address){ 
			let poolRef = self.borrowPool(pool: pool)
			if pool == "Flunks"{ 
				let tokenIDs = getAccount(staker).capabilities.get<&Flunks.Collection>(Flunks.CollectionPublicPath).borrow()?.getIDs()
				poolRef.adminClaimAll(tokenIDs: tokenIDs!, staker: staker)
			} else if pool == "Backpack"{ 
				let tokenIDs = getAccount(staker).capabilities.get<&Backpack.Collection>(Backpack.CollectionPublicPath).borrow()?.getIDs()
				poolRef.adminClaimAll(tokenIDs: tokenIDs!, staker: staker)
			}
		}
		
		access(all)
		fun adminClaimAll(staker: Address){ 
			self.adminClaimPool(pool: "Flunks", staker: staker)
			self.adminClaimPool(pool: "Backpack", staker: staker)
		}
		
		access(all)
		fun adminStakeOne(
			stakerAddress: Address,
			pool: String,
			tokenID: UInt64,
			stakedAtInSeconds: UInt64
		){ 
			// Validate stakedAtInSeconds has to be within 60 days
			if UInt64(getCurrentBlock().timestamp) - stakedAtInSeconds > 5184000{ 
				panic("StakedAtInSeconds cannot be more than 60 days in the past")
			}
			let poolRef = self.borrowPool(pool: pool)
			let adminStakingInfo =
				StakingInfo(
					_staker: stakerAddress,
					_tokenID: tokenID,
					_stakedAtInSeconds: stakedAtInSeconds,
					_pool: pool
				)
			poolRef.mutateStakingInfo(tokenID: tokenID, stakingInfo: adminStakingInfo)
		}
		
		access(all)
		fun adminStakeMany(
			stakerAddress: Address,
			pool: String,
			tokenIDs: [
				UInt64
			],
			stakedAtInSeconds: UInt64
		){ 
			for tokenID in tokenIDs{ 
				self.adminStakeOne(stakerAddress: stakerAddress, pool: pool, tokenID: tokenID, stakedAtInSeconds: stakedAtInSeconds)
			}
		}
	}
	
	access(contract)
	fun updateTracker(pool: String, tokenID: UInt64, amount: UFix64){ 
		let trackerAdmin =
			Staking.account.storage.borrow<&GUMStakingTracker.Admin>(
				from: GUMStakingTracker.AdminStoragePath
			)
			?? panic("Could not borrow a reference to the GUMStakingTracker Admin")
		trackerAdmin.updateClaimedGUM(pool: pool, tokenID: tokenID, amount: amount)
	}
	
	init(){ 
		self.AdminStoragePath = /storage/StakingAdmin
		self.Pools <-{ 
				"Flunks": <-create Pool(_name: "Flunks", _multiplier: 5.0),
				"Backpack": <-create Pool(_name: "Backpack", _multiplier: 1.0)
			}
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
