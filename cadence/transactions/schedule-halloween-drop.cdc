import FlowTransactionScheduler from 0x0fd0e3a13a5e9142
import FlowTransactionSchedulerUtils from 0x0fd0e3a13a5e9142
import HalloweenDropHandler from 0x807c3d470888cc48
import FlowToken from 0x1654653399040a61
import FungibleToken from 0xf233dcee88fe0abe

/// Step 2: Schedule the Halloween GumDrop to start automatically
/// 
/// This transaction schedules the drop to activate on Oct 31, 2025 at 12:01 AM EST
/// 
/// Arguments:
/// - delaySeconds: Number of seconds from now until execution (for testing, use small number like 60)
///                 For production: Calculate seconds until Oct 31, 12:01 AM EST
/// - priority: 0 = High, 1 = Medium, 2 = Low (use 0 for important scheduled tx)
/// - executionEffort: Gas limit for the scheduled transaction (1000 is safe)

transaction(
    delaySeconds: UFix64,
    priority: UInt8,
    executionEffort: UInt64
) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let future = getCurrentBlock().timestamp + delaySeconds
        
        let pr = priority == 0
            ? FlowTransactionScheduler.Priority.High
            : priority == 1
                ? FlowTransactionScheduler.Priority.Medium
                : FlowTransactionScheduler.Priority.Low
        
        // Estimate the fees needed
        let est = FlowTransactionScheduler.estimate(
            data: nil,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort
        )
        
        assert(
            est.timestamp != nil || pr == FlowTransactionScheduler.Priority.Low,
            message: est.error ?? "estimation failed"
        )
        
        // Withdraw fees for the scheduled transaction
        let vaultRef = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("missing FlowToken vault")
        let fees <- vaultRef.withdraw(amount: est.flowFee ?? 0.0) as! @FlowToken.Vault
        
        // If a transaction scheduler manager has not been created, create one
        if !signer.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath) {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            signer.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)
            
            // Create a public capability to the scheduled transaction manager
            let managerRef = signer.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(FlowTransactionSchedulerUtils.managerStoragePath)
            signer.capabilities.publish(managerRef, at: FlowTransactionSchedulerUtils.managerPublicPath)
        }
        
        // Get the entitled capability that will be used to create the transaction
        // Need to check both controllers because the order of controllers is not guaranteed
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        if let cap = signer.capabilities.storage
                        .getControllers(forPath: /storage/HalloweenDropHandler)[0]
                        .capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
            handlerCap = cap
        } else {
            handlerCap = signer.capabilities.storage
                        .getControllers(forPath: /storage/HalloweenDropHandler)[1]
                        .capability as! Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>
        }
        
        // Borrow a reference to the scheduled transaction manager
        let manager = signer.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath)
            ?? panic("Could not borrow a Manager reference from \(FlowTransactionSchedulerUtils.managerStoragePath)")
        
        manager.schedule(
            handlerCap: handlerCap,
            data: nil,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort,
            fees: <-fees
        )
        
        log("🎃 Halloween GumDrop scheduled for: ".concat(future.toString()))
        log("💰 Fees paid: ".concat((est.flowFee ?? 0.0).toString()).concat(" FLOW"))
    }
}
