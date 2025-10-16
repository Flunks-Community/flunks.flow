import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7
import ViewResolver from 0xf8d6e0586b0a20c7

access(all)
contract TestFlunks: NonFungibleToken {
    
    // Events
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, to: Address?)
    
    // Contract state
    access(all) var totalSupply: UInt64
    
    // Storage paths
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // NFT Resource
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        
        access(all) let id: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let image: String
        access(all) let metadata: {String: String}
        
        init(
            id: UInt64,
            name: String,
            description: String,
            image: String,
            metadata: {String: String}
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.image = image
            self.metadata = metadata
        }
        
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
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
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    for key in self.metadata.keys {
                        traits.append(MetadataViews.Trait(
                            name: key,
                            value: self.metadata[key]!,
                            displayType: nil,
                            rarity: nil
                        ))
                    }
                    return MetadataViews.Traits(traits)
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flunks.net/")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: TestFlunks.CollectionStoragePath,
                        publicPath: TestFlunks.CollectionPublicPath,
                        publicCollection: Type<&TestFlunks.Collection>(),
                        publicLinkedType: Type<&TestFlunks.Collection>(),
                        createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                            return <-TestFlunks.createEmptyCollection(nftType: Type<@TestFlunks.Collection>())
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://flunks.net/logo.png"),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Test Flunks Collection",
                        description: "A test collection of Flunks NFTs",
                        externalURL: MetadataViews.ExternalURL("https://flunks.net/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {}
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
    }
    
    // Collection Resource
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
            let token <- token as! @TestFlunks.NFT
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
        
        access(all) fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
        
        // NonFungibleToken.Receiver conformance
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@TestFlunks.NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@TestFlunks.NFT>()
        }
    }
    
    // Admin Resource - This is key for Task 1!
    access(all) resource Admin {
        
        // Step 1: Admin resource can call mintNFT function
        access(all) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            image: String,
            metadata: {String: String}
        ) {
            let newNFT <- create NFT(
                id: TestFlunks.totalSupply,
                name: name,
                description: description,
                image: image,
                metadata: metadata
            )
            
            let recipientAddress = recipient.owner!.address
            
            recipient.deposit(token: <-newNFT)
            
            emit Minted(id: TestFlunks.totalSupply, to: recipientAddress)
            
            TestFlunks.totalSupply = TestFlunks.totalSupply + 1
        }
    }
    
    // Public Functions
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <-create Collection()
    }
    
    // Contract interface conformance
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
                    storagePath: TestFlunks.CollectionStoragePath,
                    publicPath: TestFlunks.CollectionPublicPath,
                    publicCollection: Type<&TestFlunks.Collection>(),
                    publicLinkedType: Type<&TestFlunks.Collection>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-TestFlunks.createEmptyCollection(nftType: Type<@TestFlunks.Collection>())
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(url: "https://flunks.net/logo.png"),
                    mediaType: "image/png"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Test Flunks Collection",
                    description: "A test collection of Flunks NFTs",
                    externalURL: MetadataViews.ExternalURL("https://flunks.net/"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {}
                )
        }
        return nil
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/TestFlunksCollection
        self.CollectionPublicPath = /public/TestFlunksCollection
        self.AdminStoragePath = /storage/TestFlunksAdmin
        
        // Create and store Admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
