import FlowTransactionScheduler from 0x0fd0e3a13a5e9142
import FlunksGumDrop from 0x807c3d470888cc48

access(all) contract HalloweenDropHandler {
    
    /// Handler resource that implements the Scheduled Transaction interface
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // Get admin reference
            let adminRef = HalloweenDropHandler.account.storage
                .borrow<&FlunksGumDrop.Admin>(from: FlunksGumDrop.AdminStoragePath)
                ?? panic("Could not borrow Admin reference")
            
            // Start the Halloween drop
            adminRef.startDrop(
                startTime: 1730347260.0,  // Oct 31, 12:01 AM EST
                endTime: 1730606460.0,    // Nov 3, 12:01 AM EST
                gumPerFlunk: 100
            )
            
            log("🎃 Halloween GumDrop activated automatically!")
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return /storage/HalloweenDropHandler
                case Type<PublicPath>():
                    return /public/HalloweenDropHandler
                default:
                    return nil
            }
        }
    }
    
    /// Factory for the handler resource
    access(all) fun createHandler(): @Handler {
        return <- create Handler()
    }
}
