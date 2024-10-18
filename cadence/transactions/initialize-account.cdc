import HybridCustodyHelper from 0x807c3d470888cc48

transaction() {
  prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
    HybridCustodyHelper.forceRelinkCollections(signer: signer)
  }
}