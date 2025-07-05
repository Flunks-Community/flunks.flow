// SPDX-License-Identifier: UNLICENSED

import FlunksWhitelistMinter from "../contracts/FlunksWhitelistMinter.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"

transaction(
    setID: UInt64,
    numberOfTokens: UInt64,
    merchantAccount: Address,
    paymentAmount: UFix64
) {
    let paymentVault: @FungibleToken.Vault
    let buyerAddress: Address

    prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
        self.buyerAddress = signer.address
        
        // Get DUC vault reference
        let ducVaultRef = signer.storage.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Could not borrow DUC vault reference")
        
        // Withdraw payment amount
        self.paymentVault <- ducVaultRef.withdraw(amount: paymentAmount)
    }

    execute {
        // Call the public minting function
        FlunksWhitelistMinter.mintPublicNFTWithDUC(
            buyer: self.buyerAddress,
            setID: setID,
            paymentVault: <-self.paymentVault,
            merchantAccount: merchantAccount,
            numberOfTokens: numberOfTokens
        )
    }
}
