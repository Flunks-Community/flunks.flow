import Staking from 0x807c3d470888cc48

transaction(pool: String, tokenID: UInt64) {
    prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
        Staking.stakeOne(signerAuth: signer, pool: pool, tokenID: tokenID)
    }
}