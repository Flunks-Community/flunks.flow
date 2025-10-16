// Register Flunks NFT to Token List via CLI
// This bypasses the need for a web wallet connection

import MetadataViews from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448

transaction(contractAddress: Address, contractName: String) {
    prepare(signer: auth(BorrowValue) &Account) {
        // Verify the contract has the required views
        let account = getAccount(contractAddress)
        
        if let viewResolver = account.contracts.borrow<&{ViewResolver}>(name: contractName) {
            let contractViews = viewResolver.getContractViews(resourceType: nil)
            
            let hasCollectionData = contractViews.contains(Type<MetadataViews.NFTCollectionData>())
            let hasCollectionDisplay = contractViews.contains(Type<MetadataViews.NFTCollectionDisplay>())
            
            if hasCollectionData && hasCollectionDisplay {
                log("✅ Contract is valid for Token List registration")
                log("Contract: ".concat(contractAddress.toString()).concat(".").concat(contractName))
                
                // Get the display info to show what will be registered
                if let display = viewResolver.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>()) {
                    let displayView = display as! MetadataViews.NFTCollectionDisplay
                    log("Name: ".concat(displayView.name))
                    log("Description: ".concat(displayView.description))
                    log("External URL: ".concat(displayView.externalURL.url))
                }
                
                log("⚠️  Note: This transaction verifies the contract is ready.")
                log("To actually register, use the Token List website or wait for the contract deployment.")
            } else {
                panic("Contract does not meet Token List requirements")
            }
        } else {
            panic("Contract does not implement ViewResolver")
        }
    }
}
