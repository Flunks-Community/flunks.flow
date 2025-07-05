// SPDX-License-Identifier: UNLICENSED

import BackpackMinter from "../contracts/BackpackMinter.cdc"

transaction(
    flunkTokenID: UInt64,
    setID: UInt64
) {
    prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
        // Call the backpack claiming function
        BackpackMinter.claimBackPack(
            tokenID: flunkTokenID,
            signer: signer,
            setID: setID
        )
    }
}
