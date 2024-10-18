import FungibleToken from "./FungibleToken.cdc"
import FungibleTokenMetadataViews from "./FungibleTokenMetadataViews.cdc"

access(all)
contract GUM: FungibleToken{ 
	// Total supply of $GUM in existence
	access(all)
	var totalSupply: UFix64
	
	// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// Event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	// Event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let VaultReceiverPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let VaultBalancePublicPath: PublicPath
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			let vault <- from as! @GUM.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return GUM.getContractViews(resourceType: nil)
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return GUM.resolveContractView(resourceType: nil, viewType: view)
		}
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mintTokens(amount: UFix64): @GUM.Vault{ 
			pre{ 
				amount > UFix64(0):
					"Amount minted must be greater than zero"
			}
			GUM.totalSupply = GUM.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	access(all)
	resource Burner{ 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @GUM.Vault
			let amount = vault.balance
			destroy vault
			GUM.totalSupply = GUM.totalSupply - amount
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	view fun getContractViews(resourceType: Type?): [Type]{ 
		return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>(), Type<FungibleTokenMetadataViews.TotalSupply>()]
	}
	
	access(all)
	fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct?{ 
		return nil
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.VaultStoragePath = /storage/GUMVault
		self.VaultBalancePublicPath = /public/GUMBalance
		self.VaultReceiverPublicPath = /public/GUMReceiver
		self.AdminStoragePath = /storage/GUMAdmin
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&GUM.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.VaultBalancePublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.VaultReceiverPublicPath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
