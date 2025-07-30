import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448

access(all)
contract SimpleFlunksV2: NonFungibleToken {
    
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
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Serial>()
            ]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: self.image)
                    )
                
                case Type<MetadataViews.NFTCollectionData>():
                    return SimpleFlunksV2.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>())
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return SimpleFlunksV2.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>())
                
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
                
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flunks.community")
                
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
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
            let token <- token as! @SimpleFlunksV2.NFT
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
            return {Type<@SimpleFlunksV2.NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SimpleFlunksV2.NFT>()
        }
    }
    
    access(all) resource Admin {
        
        access(all) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            image: String
        ) {
            let newNFT <- create NFT(
                id: SimpleFlunksV2.totalSupply,
                name: name,
                description: description,
                image: image
            )
            
            let recipientAddress = recipient.owner!.address
            
            recipient.deposit(token: <-newNFT)
            
            emit Minted(id: SimpleFlunksV2.totalSupply, to: recipientAddress)
            
            SimpleFlunksV2.totalSupply = SimpleFlunksV2.totalSupply + 1
        }
    }
    
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <-create Collection()
    }
    
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }
    
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: SimpleFlunksV2.CollectionStoragePath,
                    publicPath: SimpleFlunksV2.CollectionPublicPath,
                    publicCollection: Type<&SimpleFlunksV2.Collection>(),
                    publicLinkedType: Type<&SimpleFlunksV2.Collection>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-SimpleFlunksV2.createEmptyCollection(nftType: Type<@SimpleFlunksV2.NFT>())
                    })
                )
            
            case Type<MetadataViews.NFTCollectionDisplay>():
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flunks Community",
                    description: "The official Flunks NFT collection on Flow mainnet",
                    externalURL: MetadataViews.ExternalURL("https://flunks.community"),
                    squareImage: MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/backpack/1c023bb17a570b7e114e35d195035e41fc60a5c3c60933daf1c780f51abfe24d.png"),
                        mediaType: "image/png"
                    ),
                    bannerImage: MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/backpack/1c023bb17a570b7e114e35d195035e41fc60a5c3c60933daf1c780f51abfe24d.png"),
                        mediaType: "image/png"
                    ),
                    socials: {
                        "website": MetadataViews.ExternalURL("https://flunks.community")
                    }
                )
        }
        return nil
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/SimpleFlunksV2Collection
        self.CollectionPublicPath = /public/SimpleFlunksV2Collection
        self.AdminStoragePath = /storage/SimpleFlunksV2Admin
        
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
