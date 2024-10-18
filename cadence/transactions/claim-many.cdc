import Staking from 0x807c3d470888cc48

transaction(pool: String, tokenIDs: [UInt64]) {
    prepare(signer: AuthAccount) {
        Staking.claimMany(signerAuth: signer, pool: pool, tokenIDs: tokenIDs)
    }
}