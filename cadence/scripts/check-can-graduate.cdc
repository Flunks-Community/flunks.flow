// Note: the contract state is probably wrong right now so features could be missing or not working as expected

import FlunksGraduationV2 from 0x807c3d470888cc48

access(all) fun main(tokenID: UInt64): Bool {
  let isGraduated = !FlunksGraduationV2.isFlunkGraduated(tokenID: tokenID)
  return isGraduated
}