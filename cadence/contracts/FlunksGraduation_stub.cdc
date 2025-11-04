// SPDX-License-Identifier: MIT
// FlunksGraduation - DEPRECATED - Use FlunksGraduationV2 instead
// This is a minimal stub to satisfy Cadence 1.0 requirements

import NonFungibleToken from 0x1d7e57aa55817448

access(all) contract FlunksGraduation {
  access(all) event ContractInitialized()
  access(all) event Graduate(address: Address, tokenID: UInt64, templateID: UInt64)
  access(all) event GraduateTimeUpdate(tokenID: UInt64, time: UInt64)

  access(all) let AdminStoragePath: StoragePath

  // Deprecated - use FlunksGraduationV2
  access(all) fun graduateFlunk(owner: auth(Storage) &Account, tokenID: UInt64) {
    // Deprecated - redirects to FlunksGraduationV2
    panic("This contract is deprecated. Please use FlunksGraduationV2")
  }

  access(all) fun isFlunkGraduated(tokenID: UInt64): Bool {
    return false
  }

  access(all) resource Admin {
    access(all) fun setGraduatedUri(tokenID: UInt64, uri: String) {
      // Deprecated
    }
  }

  init() {
    self.AdminStoragePath = /storage/FlunksGraduationAdmin
    emit ContractInitialized()
  }
}
