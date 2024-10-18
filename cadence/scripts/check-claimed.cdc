import BackpackMinter from 0x807c3d470888cc48

access(all) fun main(templateID: UInt64): Bool{
  let map = BackpackMinter.getClaimedBackPacksPerFlunkTemplateID()
  return map.containsKey(templateID)
}