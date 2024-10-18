// Note: the contract state is probably wrong right now so features could be missing or not working as expected

import FlunksGraduationV2 from 0x807c3d470888cc48

access(all) fun main(): {UInt64: UInt64} {
  return FlunksGraduationV2.getFlunksGraduationTimeTable()
}