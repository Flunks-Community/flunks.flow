transaction {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        log("Testing emulator setup...")
        log("Account address: ".concat(acct.address.toString()))
        log("Account balance: ".concat(acct.balance.toString()))
        log("✅ Emulator is working correctly!")
    }
}
