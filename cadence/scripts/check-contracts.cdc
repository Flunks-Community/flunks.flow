access(all) fun main(addr: Address): [String] {
    let acct = getAccount(addr)
    return acct.contracts.names
}
