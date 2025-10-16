import NFTList from 0x15a918087ab12d86

transaction(address: Address, contractName: String) {
    prepare(signer: &Account) {
        // This will register the NFT if it's valid and not already registered
        NFTList.ensureNFTCollectionRegistered(address, contractName)
    }
}
