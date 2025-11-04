
// SPDX-License-Identifier: MIT
import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448
import HybridCustodyHelper from 0x807c3d470888cc48
import MetadataViews from 0x1d7e57aa55817448

access(all)
contract FlunksGraduation { 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Graduate(address: Address, tokenID: UInt64, templateID: UInt64)
	
	access(all)
	event GraduateTimeUpdate(tokenID: UInt64, time: UInt64)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var GraduatedFlunks:{ UInt64: Bool}
	
	access(self)
	var tokenIDToUri:{ UInt64: String}
	
	access(all) fun graduateFlunk(owner: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account, tokenID: UInt64){ 
		pre{ 
			!FlunksGraduation.GraduatedFlunks.containsKey(tokenID):
				"Flunk has already graduated"
		}
		
		// Force re-link collections
		HybridCustodyHelper.forceRelinkCollections(signer: owner)
		
		// Check if owner is the true owner of the NFT
		let ownerCollectionTokenIds =
			HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: owner.address)
		if !ownerCollectionTokenIds.contains(tokenID){ 
			panic("Not owner")
		}
		let trueOwnerAddress =
			HybridCustodyHelper.getChildAccountAddressHoldingFlunksTokenId(
				ownerAddress: owner.address,
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
		let itemTemplateId = serial?.number ?? 0
		let itemTemplate = Flunks.getFlunksTemplateByID(templateID: itemTemplateId)
		
		// Update the NFT metadata and traits on-chain
		let admin =
			self.account.storage.borrow<&Flunks.Admin>(from: Flunks.AdminStoragePath)
			?? panic("Could not borrow a reference to the Flunks Admin")
		let adminSet = admin.borrowSet(setID: itemTemplate.addedToSet)
		let newMetadata = Flunks.getFlunksTemplateByID(templateID: itemTemplateId).getMetadata()
		if (newMetadata["Type"] ?? "") == "Graduated" {
			// Already graduated - return early
			FlunksGraduation.GraduatedFlunks[tokenID] = true
			return
		}
		newMetadata["Type"] = "Graduated"
		newMetadata["pixelUri"] = newMetadata["uri"]
		newMetadata["uri"] = FlunksGraduation.tokenIDToUri[tokenID]!
		adminSet.updateTemplateMetadata(templateID: itemTemplateId, newMetadata: newMetadata)
		// Graduate Flunks
		FlunksGraduation.GraduatedFlunks[tokenID] = true
		emit Graduate(address: owner.address, tokenID: tokenID, templateID: itemTemplateId)
	}
	
	access(all) fun isFlunkGraduated(tokenID: UInt64): Bool{ 
		return FlunksGraduation.GraduatedFlunks[tokenID] ?? false
	}

	access(all)
	resource Admin{ 
		access(all) fun setGraduatedUri(tokenID: UInt64, uri: String){ 
			if FlunksGraduation.GraduatedFlunks.containsKey(tokenID){ 
				return
			}
			FlunksGraduation.tokenIDToUri[tokenID] = uri
		}
		
		access(all) fun adminGraduatesForUsers(ownerAddress: Address, templateID: UInt64, tokenID: UInt64){ 
			// Check if owner is the true owner of the NFT
			let ownerCollectionTokenIds =
				HybridCustodyHelper.getFlunksTokenIDsFromAllLinkedAccounts(
					ownerAddress: ownerAddress
				)
			if !ownerCollectionTokenIds.contains(tokenID){ 
				panic("Not owner")
			}
			let trueOwnerAddress =
				HybridCustodyHelper.getChildAccountAddressHoldingFlunksTokenId(
					ownerAddress: ownerAddress,
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
			let itemTemplateId = serial?.number ?? 0
			let itemTemplate = Flunks.getFlunksTemplateByID(templateID: itemTemplateId)
			
			// Update the NFT metadata and traits on-chain
			let admin =
				FlunksGraduation.account.storage.borrow<&Flunks.Admin>(
					from: Flunks.AdminStoragePath
				)
				?? panic("Could not borrow a reference to the Flunks Admin")
			let adminSet = admin.borrowSet(setID: itemTemplate.addedToSet)
			let newMetadata = Flunks.getFlunksTemplateByID(templateID: itemTemplateId).getMetadata()
			newMetadata["Type"] = "Graduated"
			newMetadata["pixelUri"] = newMetadata["uri"]
			newMetadata["uri"] = FlunksGraduation.tokenIDToUri[tokenID]!
			adminSet.updateTemplateMetadata(templateID: templateID, newMetadata: newMetadata)
			// Graduate Flunks
			FlunksGraduation.GraduatedFlunks[tokenID] = true
			emit Graduate(address: ownerAddress, tokenID: tokenID, templateID: templateID)
		}
		
		access(all) fun refreshGraduatedMetadata(ownerAddress: Address, templateID: UInt64, tokenID: UInt64){ 
			emit Graduate(address: ownerAddress, tokenID: tokenID, templateID: templateID)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlunksGraduationAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.GraduatedFlunks ={} 
		self.tokenIDToUri ={} 
		emit ContractInitialized()
	}
}
