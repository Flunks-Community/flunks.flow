import HybridCustody from "./HybridCustody.cdc"
import Flunks from "./Flunks.cdc"
import Backpack from "./Backpack.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"

// Helper function to store HybirdCustody logics for Flunks & Backpacks
access(all) contract HybridCustodyHelper {
    access(all) event ContractInitialized()

    access(all) fun parseUInt64(_ string: String) : UInt64? {
        let chars : {Character : UInt64} = {
            "0" : 0 , 
            "1" : 1 , 
            "2" : 2 , 
            "3" : 3 , 
            "4" : 4 , 
            "5" : 5 , 
            "6" : 6 , 
            "7" : 7 , 
            "8" : 8 , 
            "9" : 9 
        }
        var number : UInt64 = 0
        var i = 0
        while i < string.length {
            if let n = chars[string[i]] {
                    number = number * 10 + n
            } else {
                return nil 
            }
            i = i + 1
        }
        return number 
    }

    access(all) fun getChildAccounts(parentAddress: Address): [Address] {
        // Retrieve the account associated with the parent address
        let parentAcct = getAccount(parentAddress)
        
        // Attempt to borrow a reference to the parent's Manager resource via the public path
        let parentPublicCapability = parentAcct.capabilities.borrow<&HybridCustody.Manager>(HybridCustody.ManagerPublicPath)

        // Check if the borrowing was successful
        if let parentManager = parentPublicCapability {
            // Retrieve and return the child account addresses if the reference was successfully borrowed
            return parentManager.getChildAddresses()
        } else {
            // Return an empty array if the reference could not be borrowed
            return []
        }
    }

    access(all) fun getChildAccountAddressHoldingFlunksTokenId(ownerAddress: Address, tokenID: UInt64): Address? {
    let flunksTokenIDs: [UInt64] = []
    let ownerAccount = getAccount(ownerAddress)
    let mainCollectionFlunksTokenIDs = ownerAccount.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath)?.getIDs() ?? []
    if mainCollectionFlunksTokenIDs.contains(tokenID) {
        return ownerAddress
    }

    // Retrieve linked accounts tokenIDs
    let childAccounts = HybridCustodyHelper.getChildAccounts(parentAddress: ownerAddress)
    for childAddress in childAccounts {
        let childAccount = getAccount(childAddress)
        let childFlunksCollection = childAccount.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath)
        let childFlunksCollectionTokenIDs: [UInt64] = childFlunksCollection?.getIDs() ?? []
        if childFlunksCollectionTokenIDs.contains(tokenID) {
            return childAddress
        }
    }

    return nil
}

    access(all) fun getChildAccountAddressHoldingBackpackTokenId(ownerAddress: Address, tokenID: UInt64): Address? {
        let backpackTokenIds: [UInt64] = []
        let ownerAccount = getAccount(ownerAddress)
        let mainCollectionBackpackTokenIDs: [UInt64] = ownerAccount.capabilities.borrow<&Backpack.Collection>(Backpack.CollectionPublicPath)?.getIDs() ?? []
        if mainCollectionBackpackTokenIDs.contains(tokenID) {
            return ownerAddress
        }

        // Retrieve linked accounts tokenIDs
        let childAccounts = HybridCustodyHelper.getChildAccounts(parentAddress: ownerAddress)
        for childAddress in childAccounts {
            let childAccount = getAccount(childAddress)
            let childCollection = childAccount.capabilities.borrow<&Backpack.Collection>(Backpack.CollectionPublicPath)
            let childCollectionTokenIds: [UInt64] = childCollection?.getIDs() ?? []
            if childCollectionTokenIds.contains(tokenID) {
                return childAddress
            }
        }

        return nil
    }

    access(all) fun getBackpackSlots(ownerAddress: Address, tokenID: UInt64): UInt64 {
        if let trueOwnerAddress = HybridCustodyHelper.getChildAccountAddressHoldingBackpackTokenId(ownerAddress: ownerAddress, tokenID: tokenID) {
            let trueOwnerAccount = getAccount(trueOwnerAddress)
            if let trueOwnerCollection = trueOwnerAccount.capabilities.borrow<&Backpack.Collection>(Backpack.CollectionPublicPath) {
                let item = trueOwnerCollection.borrowNFT(tokenID)
                if let traitsView = item?.resolveView(Type<MetadataViews.Traits>()) {
                    let traits = traitsView as! MetadataViews.Traits?
                    for trait in traits?.traits! {
                        if trait.name == "slots" || trait.name == "Slots" {
                            return HybridCustodyHelper.parseUInt64(trait.value as! String) ?? 0
                        }
                    }
                }
            } 
        }

        // Default slot to be 0
        return 0
    }

    access(all) fun getFlunksTokenIDsFromAllLinkedAccounts(ownerAddress: Address): [UInt64] {
        var flunksTokenIDs: [UInt64] = []
        let ownerAccount = getAccount(ownerAddress)
        let mainCollectionFlunksTokenIDs: [UInt64] = ownerAccount.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath)?.getIDs() ?? []
        for tokenID in mainCollectionFlunksTokenIDs {
            flunksTokenIDs.append(tokenID)
        }

        // Retrieve linked accounts tokenIDs
        let childAccounts = HybridCustodyHelper.getChildAccounts(parentAddress: ownerAddress)
        for childAddress in childAccounts {
            let childAccount = getAccount(childAddress)
            let childFlunksCollection = childAccount.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath)
            let childFlunksCollectionTokenIDs: [UInt64] = childFlunksCollection?.getIDs() ?? []
            for tokenID in childFlunksCollectionTokenIDs {
                flunksTokenIDs.append(tokenID)
            }
        }

        return flunksTokenIDs
    }

    access(all) fun getBackpackTokenIDsFromAllLinkedAccounts(ownerAddress: Address): [UInt64] {
        var backpackTokenIDs: [UInt64] = []
        let ownerAccount = getAccount(ownerAddress)
        let mainCollectionBackpackTokenIDs = ownerAccount.capabilities.borrow<&Backpack.Collection>(Backpack.CollectionPublicPath)?.getIDs() ?? []
        for tokenID in mainCollectionBackpackTokenIDs {
            backpackTokenIDs.append(tokenID)
        }

        // Retrieve linked accounts tokenIDs
        let childAccounts = HybridCustodyHelper.getChildAccounts(parentAddress: ownerAddress)
        for childAddress in childAccounts {
            let childAccount = getAccount(childAddress)
            let childBackpackCollection = childAccount.capabilities.borrow<&Backpack.Collection>(Backpack.CollectionPublicPath)
            let childBackpackCollectionTokenIDs: [UInt64] = childBackpackCollection?.getIDs() ?? []
            for tokenID in childBackpackCollectionTokenIDs {
                backpackTokenIDs.append(tokenID)
            }
        }

        return backpackTokenIDs
    }


    access(all) fun forceRelinkCollections(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
        // if the account doesn't already have Flunks
        if signer.storage.borrow<&Flunks.Collection>(from: Flunks.CollectionStoragePath) == nil {
            // create a new empty collection
            let collection <- Flunks.createEmptyCollection(nftType: Type<@Flunks.Collection>())
            // save it to the account
            signer.storage.save(<-collection, to: Flunks.CollectionStoragePath)
            // create a public capability for the collection
            let cap = signer.capabilities.storage.issue<&Flunks.Collection>(Flunks.CollectionStoragePath)
            signer.capabilities.publish(cap, at: Flunks.CollectionPublicPath)
        } else {
            // Unlink the existing collection (if any)
            signer.capabilities.unpublish(Flunks.CollectionPublicPath)

            // Re-link
            let cap = signer.capabilities.storage.issue<&Flunks.Collection>(Flunks.CollectionStoragePath)
            signer.capabilities.publish(cap, at: Flunks.CollectionPublicPath)
        }

        // if the account doesn't already have Backpack
        if signer.storage.borrow<&Backpack.Collection>(from: Backpack.CollectionStoragePath) == nil {
            // create a new empty collection
            let collection <- Backpack.createEmptyCollection(nftType: Type<@Backpack.Collection>())
            // save it to the account
            signer.storage.save(<-collection, to: Backpack.CollectionStoragePath)
            // create a public capability for the collection
            let cap = signer.capabilities.storage.issue<&Backpack.Collection>(Backpack.CollectionStoragePath)
            signer.capabilities.publish(cap, at: Backpack.CollectionPublicPath)
        } else {
            // Unlink the existing collection (if any)
            signer.capabilities.unpublish(Backpack.CollectionPublicPath)

            // Re-link
            let cap = signer.capabilities.storage.issue<&Backpack.Collection>(Backpack.CollectionStoragePath)
            signer.capabilities.publish(cap, at: Backpack.CollectionPublicPath)
        }
    }


    init() {
        emit ContractInitialized()
    }
}