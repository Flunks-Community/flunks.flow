// PATCH FOR Flunks.cdc - Marketplace Compatibility Improvements
// These are the specific changes to apply to your original Flunks.cdc contract

// 1. UPDATE: resolveContractView function - Add createEmptyCollectionFunction
// REPLACE the existing NFTCollectionData case in resolveContractView with:

case Type<MetadataViews.NFTCollectionData>():
    return MetadataViews.NFTCollectionData(
        storagePath: Flunks.CollectionStoragePath,
        publicPath: Flunks.CollectionPublicPath,
        publicCollection: Type<&Flunks.Collection>(),
        publicLinkedType: Type<&Flunks.Collection>(),
        createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
            return <-Flunks.createEmptyCollection(nftType: Type<@Flunks.NFT>())
        })
    )

// 2. OPTIONAL: Update external URLs to flunks.community
// In NFT resolveView function, REPLACE:
case Type<MetadataViews.ExternalURL>():
    return MetadataViews.ExternalURL("https://flunks.community")

// In contract-level NFTCollectionDisplay, REPLACE:
case Type<MetadataViews.NFTCollectionDisplay>():
    return MetadataViews.NFTCollectionDisplay(
        name: "Flunks",
        description: "Flunks are cute but mischievous high-schoolers wreaking havoc #onFlow",
        externalURL: MetadataViews.ExternalURL("https://flunks.community"),
        squareImage: MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/images/flunks.png"),
            mediaType: "image/png"
        ),
        bannerImage: MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/banner_2023.png"),
            mediaType: "image/png"
        ),
        socials: {
            "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft"),
            "website": MetadataViews.ExternalURL("https://flunks.community")
        }
    )

// 3. CRITICAL FIX: The main missing piece is the createEmptyCollectionFunction
// This was the cause of the FlowView marketplace errors we saw earlier
