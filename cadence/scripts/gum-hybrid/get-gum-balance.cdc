// Get user's GUM account info

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

access(all) fun main(address: Address): GumDropsHybrid.GumAccountInfo? {
    let account = getAccount(address)
    
    if let cap = account.capabilities.get<&GumDropsHybrid.GumAccount>(
        GumDropsHybrid.GumAccountPublicPath
    ) {
        if let gumAccount = cap.borrow() {
            return gumAccount.getInfo()
        }
    }
    
    return nil
}
