// FlunksSemesterZero - Wrapper contract for NFT token list compatibility
// This creates standard-named resources that wrap the existing Chapter5NFT
// Allows listing on Flow NFT token list without breaking existing NFT holders

import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe
import SemesterZero from 0xce9dd43888d99574

access(all) contract FlunksSemesterZero: NonFungibleToken, ViewResolver {
    
    // ========================================
    // PATHS
    // ========================================
    
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    
    // ========================================
    // EVENTS (Required by NonFungibleToken)
    // ========================================
    
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    
    // ========================================
    // NFT RESOURCE (Standard Name for Token List)
    // ========================================
    
    /// This wraps the Chapter5NFT to provide standard naming
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        
        // Reference to the actual Chapter5NFT
        access(self) let chapter5NFT: @SemesterZero.Chapter5NFT
        
        init(chapter5NFT: @SemesterZero.Chapter5NFT) {
            self.id = chapter5NFT.id
            self.chapter5NFT <- chapter5NFT
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
                        name: "Chapter 5 Completion",
                        description: "Awarded for completing both Slacker and Overachiever objectives in Chapter 5 of Flunks: Semester Zero",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://storage.googleapis.com/flunks_public/nfts/chapter5-completion.png"
                        )
                    )
                    
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://www.flunks.net/semester-zero/chapter-5")
                    
                case Type<MetadataViews.NFTCollectionData>():
                    return FlunksSemesterZero.resolveContractView(resourceType: Type<@FlunksSemesterZero.NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())
                    
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return FlunksSemesterZero.resolveContractView(resourceType: Type<@FlunksSemesterZero.NFT>(), viewType: Type<MetadataViews.NFTCollectionDisplay>())
                    
                case Type<MetadataViews.Royalties>():
                    // No royalties for Chapter 5 achievement NFTs
                    return MetadataViews.Royalties([])
                    
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)
            }
            
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlunksSemesterZero.createEmptyCollection(nftType: Type<@FlunksSemesterZero.NFT>())
        }
    }
    
    // ========================================
    // COLLECTION RESOURCE (Standard Name for Token List)
    // ========================================
    
    access(all) resource Collection: NonFungibleToken.Collection, ViewResolver.ResolverCollection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @FlunksSemesterZero.NFT
            let id = nft.id
            
            let oldToken <- self.ownedNFTs[id] <- nft
            destroy oldToken
            
            emit Deposit(id: id, to: self.owner?.address)
        }
        
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("NFT not found")
            
            emit Withdraw(id: token.id, from: self.owner?.address)
            
            return <- token
        }
        
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlunksSemesterZero.createEmptyCollection(nftType: Type<@FlunksSemesterZero.NFT>())
        }
        
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@FlunksSemesterZero.NFT>(): true}
        }
        
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@FlunksSemesterZero.NFT>()
        }
    }
    
    // ========================================
    // CONTRACT FUNCTIONS
    // ========================================
    
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }
    
    // Admin function to wrap existing Chapter5NFTs
    access(all) fun wrapChapter5NFT(chapter5NFT: @SemesterZero.Chapter5NFT): @NFT {
        return <- create NFT(chapter5NFT: <- chapter5NFT)
    }
    
    // ========================================
    // CONTRACT VIEWS (For Token List)
    // ========================================
    
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
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&FlunksSemesterZero.Collection>(),
                    publicLinkedType: Type<&FlunksSemesterZero.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <- FlunksSemesterZero.createEmptyCollection(nftType: Type<@FlunksSemesterZero.NFT>())
                    })
                )
            
            case Type<MetadataViews.NFTCollectionDisplay>():
                let squareImage = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/images/semesterzero.png"),
                    mediaType: "image/png"
                )
                let bannerImage = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/images/banner.png"),
                    mediaType: "image/png"
                )
                
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flunks: Semester Zero",
                    description: "Flunks: Semester Zero is a standalone collection that rewards users for exploring flunks.net and participating in events, challenges and completing objectives.",
                    externalURL: MetadataViews.ExternalURL("https://flunks.net"),
                    squareImage: squareImage,
                    bannerImage: bannerImage,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/flunks_nft"),
                        "discord": MetadataViews.ExternalURL("https://discord.gg/flunks")
                    }
                )
        }
        
        return nil
    }
    
    init() {
        self.CollectionStoragePath = /storage/FlunksSemesterZeroCollection
        self.CollectionPublicPath = /public/FlunksSemesterZeroCollection
        
        emit ContractInitialized()
    }
}
