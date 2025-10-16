import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
import ScopedFTProviders from 0xd5f79c5c7b388c2c
import FlowEVMBridgeConfig from 0x1e4aa0b87d10b141
import TokenList from 0xc1c18c47e763a340
import NFTList from 0xc1c18c47e763a340
import EVMTokenList from 0xfcad63f3b7a90753

transaction(
    address: Address,
    contractName: String,
    isOnboardToBridge: Bool
) {
    prepare(signer: auth(CopyValue, BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        if !isOnboardToBridge {
            // Just register to TokenList/NFTList (what you want)
            if NFTList.isValidToRegister(address, contractName) {
                NFTList.ensureNFTCollectionRegistered(address, contractName)
                log("✅ Registered Flunks to NFT List!")
            } else {
                log("⚠️  Flunks doesn't meet requirements or is already registered")
            }
        }
    }
}
