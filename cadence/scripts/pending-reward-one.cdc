import Staking from 0x807c3d470888cc48

access(all) fun main(pool: String, ownerAddress: Address, tokenID: UInt64): UFix64 {
  return Staking.pendingRewards(pool: pool, ownerAddress: ownerAddress, tokenID: tokenID)
}