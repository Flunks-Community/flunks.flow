import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7
import ViewResolver from 0xf8d6e0586b0a20c7

access(all)
contract SimpleNFT: NonFungibleToken {
    
    access(all)
    event ContractInitialized()
    
    access(all)
    event Withdraw(id: UInt64, from: Address?)
    
    access(all)
    event Deposit(id: UInt64, to: Address?)
    
    access(all)
    event Minted(id: UInt64, to: Address?)
    
    access(all)
    var totalSupply: UInt64
    
    access(all)
    let CollectionStoragePath: StoragePath
    
    access(all)
    let CollectionPublicPath: PublicPath
    
    access(all)
    resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        
        access(all)
        let id: UInt64
        
        access(all)
        let name: String
        
        access(all)
        let description: String
        
        access(all)
        let image: String
        
        init(
            id: UInt64,
            name: String,
            description: String,
            image: String
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.image = image
        }
        
        access(all)
        view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }
        
        access(all)
        fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.image
                        )
                    )
            }
            return nil
        }
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
    }
    
    access(all)
    resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection {
        
        access(all)
        var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            
            emit Withdraw(id: token.id, from: self.owner?.address)
            
            return <-token
        }
        
        access(all)
        fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @SimpleNFT.NFT
            
            let id: UInt64 = token.id
            
            let oldToken <- self.ownedNFTs[id] <- token
            
            emit Deposit(id: id, to: self.owner?.address)
            
            destroy oldToken
        }
        
        access(all)
        view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all)
        view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(all)
        fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-create Collection()
        }
    }
    
    access(all)
    fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <-create Collection()
    }
    
    access(all)
    fun mintNFT(
        recipient: &{NonFungibleToken.CollectionPublic},
        name: String,
        description: String,
        image: String
    ) {
        let newNFT <- create NFT(
            id: SimpleNFT.totalSupply,
            name: name,
            description: description,
            image: image
        )
        
        let recipientAddress = recipient.owner!.address
        
        recipient.deposit(token: <-newNFT)
        
        emit Minted(id: SimpleNFT.totalSupply, to: recipientAddress)
        
        SimpleNFT.totalSupply = SimpleNFT.totalSupply + 1
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/SimpleNFTCollection
        self.CollectionPublicPath = /public/SimpleNFTCollection
        
        emit ContractInitialized()
    }
}
