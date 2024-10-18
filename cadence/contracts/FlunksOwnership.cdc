pub contract FlunksOwnershipHelper {

    pub event ContractInitialized()

    access(self) var FlunksOwnership: {UInt64: Address}
    access(self) var BackpacksOwnership: {UInt64: Address}
    access(self) var IkonOwnership: {UInt64: Address}

    pub resource Admin {
        pub fun adminUpdateFlunksOwnership(tokenIDs: [UInt64], ownerAddresses: [Address]) {
            var i = 0
            while i < tokenIDs.length {
                FlunksOwnershipHelper.FlunksOwnership[tokenIDs[i]] = ownerAddresses[i]
                i = i + 1
            }
        }
    }

    init() {
        self.FlunksOwnership = {}
        self.BackpacksOwnership = {}
        self.IkonOwnership = {}

        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}