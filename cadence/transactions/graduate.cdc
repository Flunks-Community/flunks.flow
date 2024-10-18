// Note: the contract state is probably wrong right now so features could be missing or not working as expected

import FlunksGraduationV2 from 0x807c3d470888cc48

transaction(tokenID: UInt64) {
    prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
      FlunksGraduationV2.graduateFlunk(owner: signer, tokenID: tokenID)
    }
}