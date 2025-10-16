// SPDX-License-Identifier: MIT
import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"

// NonFungibleGum is a temp NFT resource for $GUM
// It will be replaced by the $GUM Fungible Token when Dapper allows it
pub contract NonFungibleGUM: NonFungibleToken {
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event WithdrawWithValue(id: UInt64, value: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event DepositWithValue(id: UInt64, value: UInt64, to: Address?)
    pub event Mint(id: UInt64, to: Address)
    pub event Burn(id: UInt64, value: UInt64)

    pub event BillCreated(value: UInt64, uri: String)

    pub resource interface GUMCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowGUM(id: UInt64): &NonFungibleGUM.NFT? {
            post {
                (result == nil) || (result?.id == id):
                "Cannot borrow Patch reference: The ID of the returned reference is incorrect"
            }
        }
        pub fun totalValue(): UInt64
        pub fun batchDeposit(collection: @Collection)
    }

    access(self) var Bills: @{UInt64: Bill}
    access(self) var BillInfos: {UInt64: BillInfo}

    pub struct BillInfo {
        pub let value: UInt64
        pub var uri: String
        pub var supply: UInt64

        pub fun updateSupply(supply: UInt64) {
            self.supply = supply
        }

        init(value: UInt64, uri: String, supply: UInt64) {
            self.value = value
            self.uri = uri
            self.supply = supply
        }
    }

    pub resource Bill {
        pub let value: UInt64
        pub var uri: String
        pub var supply: UInt64

        pub fun getValue(): UInt64 {
            return self.value
        }

        pub fun getUri(): String {
            return self.uri
        }

        pub fun updateUri(uri: String) {
            self.uri = uri
        }

        pub fun getValueSum(): UInt64 {
            return self.value * self.supply
        }

        pub fun mint(): @NFT {
            let newNFT <- create NFT(id: NonFungibleGUM.totalSupply, billValue: self.value)
            
            // Sync supply
            self.supply = self.supply + 1
            NonFungibleGUM.totalSupply = NonFungibleGUM.totalSupply + 1
            NonFungibleGUM.BillInfos[self.value]!.updateSupply(supply: self.supply)

            return <-newNFT
        }

        pub fun batchMint(amount: UInt64): @NonFungibleGUM.Collection {
            let collection <- NonFungibleGUM.createEmptyCollection()

            var counter = 0 as UInt64
            while counter < amount {
                let newNFT <- create NFT(id: NonFungibleGUM.totalSupply, billValue: self.value)
                collection.deposit(token: <-newNFT)
                counter = counter + 1

                // Sync supply
                self.supply = self.supply + 1
                NonFungibleGUM.totalSupply = NonFungibleGUM.totalSupply + 1
            }

            // Sync supply
            NonFungibleGUM.BillInfos[self.value]!.updateSupply(supply: self.supply)

            return <- (collection as! @NonFungibleGUM.Collection)
        }

        pub fun burn(nft: @NFT) {
            emit Burn(id: nft.id, value: nft.billValue)

            destroy nft
            self.supply = self.supply - 1

            // Sync
            NonFungibleGUM.BillInfos[self.value]!.updateSupply(supply: self.supply)
        }

        init(value: UInt64, uri: String) {
            pre {
                !NonFungibleGUM.Bills.keys.contains(value):
                    "Bill with this value already exists"
            }

            self.value = value
            self.uri = uri
            self.supply = 0

            NonFungibleGUM.BillInfos[value] = BillInfo(value: value, uri: uri, supply: 0)
        }        
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let billValue: UInt64

        pub fun name(): String {
            return "$".concat(self.billValue.toString()).concat(" Bill")
        }

        pub fun uri(): String {
            return NonFungibleGUM.BillInfos[self.id]!.uri
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Edition>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                return MetadataViews.Display(
                    name: self.name(),
                    description: self.name(),
                    thumbnail: MetadataViews.HTTPFile(
                        url: self.uri()
                    )
                )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(url: "https://flunks.net/")

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: NonFungibleGUM.CollectionStoragePath,
                        publicPath: NonFungibleGUM.CollectionPublicPath,
                        providerPath: /private/NonFungibleGUMPrivateProvider,
                        publicCollection: Type<&NonFungibleGUM.Collection{NonFungibleToken.CollectionPublic}>(),
                        publicLinkedType: Type<&NonFungibleGUM.Collection{NonFungibleToken.CollectionPublic, NonFungibleGUM.GUMCollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&NonFungibleGUM.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: (fun (): @NonFungibleToken.Collection {
                        return <-NonFungibleGUM.createEmptyCollection()
                        }),
                )

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://storage.googleapis.com/zeero-public/GUM_icon.svg"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "NonFungibleGUM",
                        description: "NonFungibleGum #onFlow",
                        externalURL: MetadataViews.ExternalURL("https://flunks.net/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft")
                        }
                )
                
                case Type<MetadataViews.Edition>():
                    return MetadataViews.Edition(
                        name: "NonFungibleGUM",
                        number: self.id,
                        max: 9999
                    )

                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        cutInfos: []
                    )
            }

            return nil
        }

        init (id: UInt64, billValue: UInt64) {
            self.id = id
            self.billValue = billValue
        }
    }
    

    pub resource Collection: GUMCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let tokenRef = self.borrowGUM(id: withdrawID)
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            emit WithdrawWithValue(id: token.id, value: tokenRef!.billValue, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @NonFungibleGUM.NFT
            let id: UInt64 = token.id
            emit DepositWithValue(id: id, value: token.billValue, to: self.owner?.address)
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        pub fun batchDeposit(collection: @Collection) {
            let keys = collection.getIDs()
            for key in keys {
                self.deposit(token: <-collection.withdraw(withdrawID: key))
            }
            destroy collection
        }

        pub fun batchWithdraw(tokenIDs: [UInt64]): @NonFungibleToken.Collection {
            let collection <- NonFungibleGUM.createEmptyCollection()
            for id in tokenIDs {
                collection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            return <-collection
        }

        pub fun aggregateByFaceValue(): {UInt64: [UInt64]} {
            let aggregated: {UInt64: [UInt64]} = {} // {FaceValue: [TokenIDs]}
            for id in self.ownedNFTs.keys {
                let token = self.borrowGUM(id: id)!
                let faceValue = token.billValue
                if aggregated[faceValue] == nil {
                    aggregated[faceValue] = []
                }
                aggregated[faceValue]!.append(id)
            }

            return aggregated
        }

        pub fun batchWithdrawByBillFaceValue(bills: {UInt64: UInt64}): @NonFungibleToken.Collection {
            let collection <- NonFungibleGUM.createEmptyCollection()
            let aggregated = self.aggregateByFaceValue()
            
            for faceValue in bills.keys {
                let requiredCount = bills[faceValue]!

                var counter = 0 as UInt64

                while counter < requiredCount {
                    let tokenID = aggregated[faceValue]!.remove(at: 0)
                    let token <-self.withdraw(withdrawID: tokenID)
                    collection.deposit(token: <- token)

                    counter = counter + 1
                }
            }

            return <-collection
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowGUM(id: UInt64): &NonFungibleGUM.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &NonFungibleGUM.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let castedNFT = nft as! &NonFungibleGUM.NFT
                return castedNFT
        }

        pub fun totalValue(): UInt64 {
            var total: UInt64 = 0
            for id in self.ownedNFTs.keys {
                let nft = self.borrowGUM(id: id)!
                total = total + nft.billValue
            }
            return total
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }
  
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource Admin {
        pub fun createBill(value: UInt64, uri: String) {
            pre {
                NonFungibleGUM.Bills[value] == nil: "Bill already created"
            }

            let newBill <- create Bill(value: value, uri: uri)
            NonFungibleGUM.Bills[value] <-! newBill

            emit BillCreated(value: value, uri: uri)
        }

        pub fun borrowBill(billValue: UInt64): &Bill {
            pre {
                NonFungibleGUM.Bills[billValue] != nil:
                    "Cannot borrow Bill: Bill value doesn't exist"
            }
            
            return (&NonFungibleGUM.Bills[billValue] as &Bill?)!
        }

        pub fun mint(billValue: UInt64): @NonFungibleGUM.NFT {
            let bill = self.borrowBill(billValue: billValue)
            let newNFT <- bill.mint()
            return <- newNFT
        }

        pub fun batchMint(billValue: UInt64, amount: UInt64): @NonFungibleGUM.Collection {
            let bill = self.borrowBill(billValue: billValue)
            let mintedBills <- bill.batchMint(amount: amount)
            return <- mintedBills
        }
    }

    pub fun exchange(targetBills: {UInt64: UInt64}, incomingBills: {UInt64: UInt64}, signer: AuthAccount) {
        var targetValue = 0 as UInt64
        for bill_key in targetBills.keys {
            let bill_amount = targetBills[bill_key]!
            targetValue = targetValue + (bill_key * bill_amount)
        }

        let selfAdmin = self.account.borrow<&NonFungibleGUM.Admin>(from: NonFungibleGUM.AdminStoragePath)
            ?? panic("Could not borrow a reference to the NonFungibleGUM Admin")

        let collectionRef = signer.borrow<&NonFungibleGUM.Collection>(from: NonFungibleGUM.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the provided auth account's NonFungibleGUM Collection")
        let incomingBills <- collectionRef.batchWithdrawByBillFaceValue(bills: incomingBills) as! @NonFungibleGUM.Collection

        let totalValue = incomingBills.totalValue()
        if totalValue != targetValue {
            panic("Insufficient funds for exchange")
        }

        // destroy incoming GUMS
        for id in incomingBills.getIDs() {
            let nft <- incomingBills.withdraw(withdrawID: id) as! @NonFungibleGUM.NFT
            let bill = selfAdmin.borrowBill(billValue: nft.billValue)
            bill.burn(nft: <-nft)
        }
        destroy <- incomingBills

        // create new gums that the user wants to exchange for
        let collection <- (self.createEmptyCollection() as! @NonFungibleGUM.Collection)
        for bill_key in targetBills.keys {
            let bill = selfAdmin.borrowBill(billValue: bill_key)
            let bill_amount = targetBills[bill_key]!
            collection.batchDeposit(collection: <- bill.batchMint(amount: bill_amount))
        }
        
        collectionRef.batchDeposit(collection: <-collection)
    }

    init() {
        self.CollectionStoragePath = /storage/NonFungibleGUMCollection
        self.CollectionPublicPath = /public/NonFungibleGUMCollection
        self.AdminStoragePath = /storage/NonFungibleGUMAdmin

        self.Bills <- {}
        self.BillInfos = {}

        self.totalSupply = 0

        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}