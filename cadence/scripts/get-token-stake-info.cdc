import Staking from 0x807c3d470888cc48

access(all) fun main(signerAddress: Address, pool: String, tokenID: UInt64): Staking.StakingInfo? {
  return Staking.getStakingInfo(signerAddress: signerAddress, pool: pool, tokenID: tokenID)
}