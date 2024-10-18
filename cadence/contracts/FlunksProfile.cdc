// SPDX-License-Identifier: MIT
import Flunks from "./Flunks.cdc"
import MetadataViews from "./MetadataViews.cdc"

access(all)
contract FlunksProfile{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var WalletToProfile:{ Address:{ String: String}}
	
	access(all)
	fun updateProfileImg(owner: AuthAccount, tokenID: UInt64){ 
		// Validate user's ownership of the token for PFP
		let collection =
			getAccount(owner.address).capabilities.get<&Flunks.Collection>(
				Flunks.CollectionPublicPath
			).borrow()!
		let ownerCollectionTokenIds = collection.getIDs()
		if !ownerCollectionTokenIds.contains(tokenID){ 
			panic("Not owner")
		}
		
		// Get the metadata for the token in the generic way
		let item = collection.borrowNFT(id: tokenID)
		let view =
			item.resolveView(Type<MetadataViews.Display>())
			?? panic("Could not resolve the item's metadata view")
		let display = view as! MetadataViews.Display
		let thumbnail = display.thumbnail as! MetadataViews.HTTPFile
		let editionView =
			item.resolveView(Type<MetadataViews.Edition>())
			?? panic("Could not get the item's edition view")
		let edition = editionView as! MetadataViews.Edition
		if !FlunksProfile.WalletToProfile.containsKey(owner.address){ 
			FlunksProfile.WalletToProfile[owner.address] ={ "profilePictureTokenId": tokenID.toString(), "profilePictureTemplateId": edition.number.toString(), "profilePictureUrl": thumbnail.url}
		} else{ 
			let currProfileOjb = FlunksProfile.WalletToProfile[owner.address]!
			currProfileOjb["profilePictureUrl"] = thumbnail.url
			currProfileOjb["profilePictureTokenId"] = tokenID.toString()
			currProfileOjb["profilePictureTemplateId"] = edition.number.toString()
			FlunksProfile.WalletToProfile[owner.address] = currProfileOjb
		}
	}
	
	access(all)
	fun getProfile(address: Address):{ String: String}{ 
		return self.WalletToProfile[address] ??{} 
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateProfile(address: Address, newProfileObj:{ String: String}){} 
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlunksProfileAdmin
		self.WalletToProfile ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
