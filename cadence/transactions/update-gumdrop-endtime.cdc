import SemesterZero from 0x807c3d470888cc48

/// Update Halloween GumDrop End Time
/// Closes current drop and creates new one with November 3, 2025 @ 12:00 PM Central deadline
transaction(newEndTime: UFix64) {
    
    prepare(admin: auth(Storage) &Account) {
        // Borrow admin resource
        let adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference")
        
        // Get current drop info before closing
        let currentDrop = SemesterZero.activeGumDrop
        assert(currentDrop != nil, message: "No active GumDrop to update")
        
        let dropId = currentDrop!.dropId
        let amount = currentDrop!.amount
        let startTime = currentDrop!.startTime
        
        // Convert eligible users dictionary keys to array
        var eligibleList: [Address] = []
        for address in currentDrop!.eligibleUsers.keys {
            eligibleList.append(address)
        }
        
        // Calculate duration from NOW to new end time
        // (GumDrop constructor uses getCurrentBlock().timestamp as start time)
        let currentTime = getCurrentBlock().timestamp
        let durationSeconds = newEndTime - currentTime
        
        // Close existing drop
        adminRef.closeGumDrop()
        
        // Create new drop with calculated duration
        adminRef.createGumDrop(
            dropId: "halloween-2025",
            eligibleAddresses: eligibleList,
            amount: amount,
            durationSeconds: durationSeconds
        )
    }
    
    execute {
        log("GumDrop deadline updated to November 3, 2025 @ 12:00 PM Central")
    }
}
