// SPDX-License-Identifier: UNLICENSED
import Flunks from "./Flunks.cdc"
import Backpack from "./Backpack.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import HybridCustodyHelper from "./HybridCustodyHelper.cdc"

access(all)
contract BackpackMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event BackpackClaimed(FlunkTokenID: UInt64, BackpackTokenID: UInt64, signer: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var backpackClaimedPerFlunkTokenID:{ UInt64: UInt64} // Flunk token ID: backpack token ID
	
	
	access(self)
	var backpackClaimedPerFlunkTemplate:{ UInt64: UInt64} // Flunks template ID: backpack token ID
	
	
	access(all)
	fun claimBackPack(tokenID: UInt64, signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, setID: UInt64){ 
		// verify that the token is not already claimed
		pre{ 
			tokenID >= 0 && tokenID <= 9998:
				"Invalid Flunk token ID"
			!BackpackMinter.backpackClaimedPerFlunkTokenID.containsKey(tokenID):
				"Token ID already claimed"
		}
		
		// verify Flunk ownership
		let ownerCollectionTokenIds =
			HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: signer.address)
		if !ownerCollectionTokenIds.contains(tokenID){ 
			panic("signer is not owner of Flunk")
		}
		
		// HybridCustodyHelper to force re-linking collections
		HybridCustodyHelper.forceRelinkCollections(signer: signer)
		
		// Get recipient receiver capoatility
		let recipient = getAccount(signer.address)
		let backpackReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Backpack.CollectionPublicPath
			).borrow()
			?? panic("Could not get receiver reference to the Backpack NFT Collection")
		
		// mint backpack to signer
		let admin =
			self.account.storage.borrow<&Backpack.Admin>(from: Backpack.AdminStoragePath)
			?? panic("Could not borrow a reference to the Backpack Admin")
		let backpackSet = admin.borrowSet(setID: setID)
		let backpackNFT <- backpackSet.mintNFT()
		let backpackTokenID = backpackNFT.id
		emit BackpackClaimed(
			FlunkTokenID: tokenID,
			BackpackTokenID: backpackNFT.id,
			signer: signer.address
		)
		backpackReceiver.deposit(token: <-backpackNFT)
		BackpackMinter.backpackClaimedPerFlunkTokenID[tokenID] = backpackTokenID
		let trueOwnerAddress =
			HybridCustodyHelper.getChildAccountAddressHoldingFlunksTokenId(
				ownerAddress: signer.address,
				tokenID: tokenID
			)
			?? panic("Could not find true owner for specified tokenID")
		let trueOwnercollection =
			getAccount(trueOwnerAddress).capabilities.get<&Flunks.Collection>(
				Flunks.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow a reference to the account's NFT collection")
		let item = trueOwnercollection.borrowNFT(tokenID)
		let serialView =
			item?.resolveView(Type<MetadataViews.Serial>())
			?? panic("Could not get the item's serial view")
		let serial = serialView as! MetadataViews.Serial?
		let templateID = serial?.number ?? 0
		BackpackMinter.backpackClaimedPerFlunkTemplate[templateID] = backpackTokenID
	}
	
	access(all)
	fun getClaimedBackPacksPerFlunkTokenID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTokenID
	}
	
	access(all)
	fun getClaimedBackPacksPerFlunkTemplateID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTemplate
	}
	
	init(){ 
		self.AdminStoragePath = /storage/BackpackMinterAdmin
		self.backpackClaimedPerFlunkTokenID ={} 
		self.backpackClaimedPerFlunkTemplate ={} 
		emit ContractInitialized()
	}
}
