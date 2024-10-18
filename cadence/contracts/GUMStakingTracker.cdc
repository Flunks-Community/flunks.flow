access(all)
contract GUMStakingTracker{ 
	access(self)
	var flunksClaimedGum:{ UInt64: UFix64}
	
	access(self)
	var backpackClaimedGum:{ UInt64: UFix64}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateClaimedGUM(pool: String, tokenID: UInt64, amount: UFix64){ 
			if pool == "Flunks"{ 
				let existingAmount = GUMStakingTracker.flunksClaimedGum[tokenID] ?? 0.0
				let newAmount = existingAmount + amount
				GUMStakingTracker.flunksClaimedGum[tokenID] = newAmount
			} else if pool == "Backpack"{ 
				let existingAmount = GUMStakingTracker.backpackClaimedGum[tokenID] ?? 0.0
				let newAmount = existingAmount + amount
				GUMStakingTracker.backpackClaimedGum[tokenID] = newAmount
			}
		}
	}
	
	access(all)
	fun getClaimedFlunksTracker():{ UInt64: UFix64}{ 
		return self.flunksClaimedGum
	}
	
	access(all)
	fun getClaimedBackpackTracker():{ UInt64: UFix64}{ 
		return self.backpackClaimedGum
	}
	
	init(){ 
		self.AdminStoragePath = /storage/GUMStakingTrackerAdmin
		self.flunksClaimedGum ={} 
		self.backpackClaimedGum ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
