import NFTList from 0x15a918087ab12d86

access(all) fun main(address: Address, contractName: String): Bool {
    return NFTList.isRegistered(address: address, contractName: contractName)
}
