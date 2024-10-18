// SPDX-License-Identifier: MIT

pub contract FlunksIdentity {
    pub event ContractInitialized()
    pub event IdentityInitialized(owner: Address);

    access(self) var mainWalletToSecondaryWallet: {Address: Address?};
    access(self) var secondaryWalletToMainWallet: {Address: Address?};
    access(self) var mainWalletToPendingSecondaryWallet: {Address: Address};

    pub fun initializeIdentity(owner: AuthAccount) {
        pre {
            self.hasIdentity(owner: owner.address) == false: "Identity already initialized"
            !self.isLinkedAsSecondaryAccount(account: owner.address) == false: "Account already linked as secondary wallet"
        }

        FlunksIdentity.mainWalletToSecondaryWallet = {owner.address: nil}
    }

    pub fun authorizeSecondaryWallet(owner: AuthAccount, secondaryWalletAddress: Address) {
        FlunksIdentity.mainWalletToPendingSecondaryWallet[owner.address] = secondaryWalletAddress
    }

    pub fun confirmWithSecondaryWallet(secondaryWalletAuth: AuthAccount, mainWalletAddress: Address) {
        let authorizxedSecondaryWalletAddress = FlunksIdentity.mainWalletToPendingSecondaryWallet[mainWalletAddress]

        if (secondaryWalletAuth.address != authorizxedSecondaryWalletAddress) {
            panic("Secondary wallet address not authorized by the identity owner")
        }

        FlunksIdentity.mainWalletToSecondaryWallet[mainWalletAddress] = secondaryWalletAuth.address
        FlunksIdentity.mainWalletToPendingSecondaryWallet.remove(key: mainWalletAddress)
    }

    pub fun removeSecondaryWallet(owner: AuthAccount) {
        pre {
            FlunksIdentity.hasSecondaryWallet(owner: owner.address): "Secondary wallet not found"
        }
        FlunksIdentity.mainWalletToSecondaryWallet[owner.address] = nil
        let secondaryAddress = FlunksIdentity.mainWalletToSecondaryWallet[owner.address]!
        FlunksIdentity.secondaryWalletToMainWallet.remove(key: secondaryAddress!)
        if FlunksIdentity.mainWalletToPendingSecondaryWallet[owner.address] != nil {
            FlunksIdentity.mainWalletToPendingSecondaryWallet.remove(key: owner.address)
        }
        
    }

    pub fun secondaryWalletRemoveSelf(secondaryWalletAuth: AuthAccount) {
        pre {
            FlunksIdentity.isLinkedAsSecondaryAccount(account: secondaryWalletAuth.address): "Secondary wallet not found"
        }
        let mainWalletAddress = FlunksIdentity.secondaryWalletToMainWallet[secondaryWalletAuth.address]!!

        FlunksIdentity.mainWalletToSecondaryWallet[mainWalletAddress] = nil
        FlunksIdentity.secondaryWalletToMainWallet.remove(key: secondaryWalletAuth.address)
        if FlunksIdentity.mainWalletToPendingSecondaryWallet[mainWalletAddress] != nil {
            FlunksIdentity.mainWalletToPendingSecondaryWallet.remove(key: mainWalletAddress)
        }
    }

    pub fun getSecondaryWalletAddress(owner: Address): Address?? {
        let secondaryWalletAddress = FlunksIdentity.mainWalletToSecondaryWallet[owner]
        return secondaryWalletAddress
    }

    pub fun getMainWalletAddressFromSecondaryWallet(secondaryWalletAddress: Address): Address?? {
        let mainWalletAddress = FlunksIdentity.secondaryWalletToMainWallet[secondaryWalletAddress]
        if mainWalletAddress == secondaryWalletAddress {
            return nil
        }
        return mainWalletAddress
    }

    pub fun hasIdentity(owner: Address): Bool {
        if FlunksIdentity.mainWalletToSecondaryWallet.containsKey(owner) {
            return true
        }

        return false
    }

    pub fun isLinkedAsSecondaryAccount(account: Address): Bool {
        if FlunksIdentity.secondaryWalletToMainWallet.containsKey(account) {
            return true
        }

        return false
    }

    pub fun hasSecondaryWallet(owner: Address): Bool {
        let secondaryWalletAddress = FlunksIdentity.mainWalletToSecondaryWallet[owner]
        if secondaryWalletAddress != nil {
            return true
        }
        return false
    }

    init() {
        self.mainWalletToSecondaryWallet = {}
        self.secondaryWalletToMainWallet = {}
        self.mainWalletToPendingSecondaryWallet = {}
        emit ContractInitialized()
    }
}