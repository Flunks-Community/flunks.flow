import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7
import ViewResolver from 0xf8d6e0586b0a20c7

access(all)
contract SimpleFlunksWithTraits: NonFungibleToken {
    
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, to: Address?)
    
    access(all) var totalSupply: UInt64
    
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // Trait structure for NFT attributes
    access(all) struct Trait {
        access(all) let name: String
        access(all) let value: AnyStruct
        access(all) let displayType: String?
        access(all) let rarity: String?
        
        init(name: String, value: AnyStruct, displayType: String?, rarity: String?) {
            self.name = name
            self.value = value
            self.displayType = displayType
            self.rarity = rarity
        }
    }
    
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        
        access(all) let id: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let image: String
        access(all) let traits: [Trait]
        access(all) let externalURL: String?
        access(all) let animationURL: String?
        access(all) let edition: UInt64?
        access(all) let maxEdition: UInt64?
        
        init(
            id: UInt64, 
            name: String, 
            description: String, 
            image: String,
            traits: [Trait],
            externalURL: String?,
            animationURL: String?,
            edition: UInt64?,
            maxEdition: UInt64?
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.image = image
            self.traits = traits
            self.externalURL = externalURL
            self.animationURL = animationURL
            self.edition = edition
            self.maxEdition = maxEdition
        }
        
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Royalties>()
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
                
                case Type<MetadataViews.Traits>():
                    let traitsView: [MetadataViews.Trait] = []
                    for trait in self.traits {
                        traitsView.append(MetadataViews.Trait(
                            name: trait.name,
                            value: trait.value,
                            displayType: trait.displayType,
                            rarity: trait.rarity != nil ? MetadataViews.Rarity(
                                score: nil,
                                max: nil,
                                description: trait.rarity!
                            ) : nil
                        ))
                    }
                    return MetadataViews.Traits(traitsView)
                
                case Type<MetadataViews.Editions>():
                    if self.edition != nil && self.maxEdition != nil {
                        return MetadataViews.Editions([
                            MetadataViews.Edition(
                                name: "SimpleFlunks Edition",
                                number: self.edition!,
                                max: self.maxEdition
                            )
                        ])
                    }
                    return nil
                
                case Type<MetadataViews.ExternalURL>():
                    if self.externalURL != nil {
                        return MetadataViews.ExternalURL(self.externalURL!)
                    }
                    return nil
                
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
                
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
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
            let token <- token as! @SimpleFlunksWithTraits.NFT
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
            return {Type<@SimpleFlunksWithTraits.NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SimpleFlunksWithTraits.NFT>()
        }
    }
    
    access(all) resource Admin {
        
        access(all) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            image: String,
            traits: [Trait],
            externalURL: String?,
            animationURL: String?,
            edition: UInt64?,
            maxEdition: UInt64?
        ) {
            let newNFT <- create NFT(
                id: SimpleFlunksWithTraits.totalSupply,
                name: name,
                description: description,
                image: image,
                traits: traits,
                externalURL: externalURL,
                animationURL: animationURL,
                edition: edition,
                maxEdition: maxEdition
            )
            
            let recipientAddress = recipient.owner!.address
            
            recipient.deposit(token: <-newNFT)
            
            emit Minted(id: SimpleFlunksWithTraits.totalSupply, to: recipientAddress)
            
            SimpleFlunksWithTraits.totalSupply = SimpleFlunksWithTraits.totalSupply + 1
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
                    storagePath: SimpleFlunksWithTraits.CollectionStoragePath,
                    publicPath: SimpleFlunksWithTraits.CollectionPublicPath,
                    publicCollection: Type<&SimpleFlunksWithTraits.Collection>(),
                    publicLinkedType: Type<&SimpleFlunksWithTraits.Collection>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-SimpleFlunksWithTraits.createEmptyCollection(nftType: Type<@SimpleFlunksWithTraits.Collection>())
                    })
                )
        }
        return nil
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/SimpleFlunksWithTraitsCollection
        self.CollectionPublicPath = /public/SimpleFlunksWithTraitsCollection
        self.AdminStoragePath = /storage/SimpleFlunksWithTraitsAdmin
        
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit ContractInitialized()
    }
}
