import FlunksSemesterZero from "../contracts/FlunksSemesterZero.cdc"

// Deploy FlunksSemesterZero wrapper contract
// This creates standard-named NFT/Collection resources for token list compatibility
transaction(code: String) {
    
    prepare(signer: auth(AddContract) &Account) {
        // Deploy the wrapper contract
        signer.contracts.add(
            name: "FlunksSemesterZero",
            code: code.utf8
        )
    }
    
    execute {
        log("✅ FlunksSemesterZero wrapper contract deployed!")
        log("This contract wraps Chapter5NFT with standard NFT/Collection names")
        log("Now eligible for Flow NFT token list registration")
    }
}
