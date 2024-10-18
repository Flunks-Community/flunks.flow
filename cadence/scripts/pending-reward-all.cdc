import Staking from 0x807c3d470888cc48

access(all) fun main(address: Address): UFix64 {
  return Staking.pendingRewardsPerWallet(address: address)
}