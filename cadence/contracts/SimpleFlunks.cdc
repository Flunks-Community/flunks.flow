import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"

access(all)
contract SimpleFlunks: NonFungibleToken {
    
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, to: Address?)
    
    access(all) var totalSupply: UInt64
    
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        
        access(all) let id: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let image: String
        
        init(id: UInt64, name: String, description: String, image: String) {
            self.id = id
            self.name = name
            self.description = description
            self.image = image
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<MetadataViews.Display>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: self.image)
                    )
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
    }
    
    access(all) resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection {
        
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @SimpleFlunks.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@SimpleFlunks.NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SimpleFlunks.NFT>()
        }
    }
    
    // This is the key Admin resource for Task 1!
    access(all) resource Admin {
        
        // Step 1: Admin resource can call function mintNFT ✅
        access(all) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            image: String
        ) {
            let newNFT <- create NFT(
                id: SimpleFlunks.totalSupply,
                name: name,
                description: description,
                image: image
            )
            
            let recipientAddress = recipient.owner!.address
            
            recipient.deposit(token: <-newNFT)
            
            emit Minted(id: SimpleFlunks.totalSupply, to: recipientAddress)
            
            SimpleFlunks.totalSupply = SimpleFlunks.totalSupply + 1
        }
    }
    
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <-create Collection()
    }
    
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [Type<MetadataViews.NFTCollectionData>()]
    }
    
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: SimpleFlunks.CollectionStoragePath,
                    publicPath: SimpleFlunks.CollectionPublicPath,
                    publicCollection: Type<&SimpleFlunks.Collection>(),
                    publicLinkedType: Type<&SimpleFlunks.Collection>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-SimpleFlunks.createEmptyCollection(nftType: Type<@SimpleFlunks.Collection>())
                    })
                )
        }
        return nil
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/SimpleFlunksCollection
        self.CollectionPublicPath = /public/SimpleFlunksCollection
        self.AdminStoragePath = /storage/SimpleFlunksAdmin
        
        // Create and store Admin resource - This enables Step 1!
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
