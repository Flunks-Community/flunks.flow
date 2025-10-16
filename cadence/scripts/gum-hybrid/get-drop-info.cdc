// Get specific drop info

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

access(all) fun main(dropID: UInt64): GumDropsHybrid.SpecialDropInfo? {
    return GumDropsHybrid.getSpecialDropInfo(dropID: dropID)
}
