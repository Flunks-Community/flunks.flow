import SemesterZero from "../contracts/SemesterZero.cdc"

/// Check all active drops and their details
/// Perfect for displaying on website
///
/// USAGE:
/// flow scripts execute ./cadence/scripts/check-halloween-drop.cdc

access(all) fun main(): [SemesterZero.SpecialDropInfo] {
    return SemesterZero.getActiveDrops()
}
