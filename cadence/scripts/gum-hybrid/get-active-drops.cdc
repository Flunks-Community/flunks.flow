// Get all active special drops

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

access(all) fun main(): [GumDropsHybrid.SpecialDropInfo] {
    return GumDropsHybrid.getActiveDrops()
}
