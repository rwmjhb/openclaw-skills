/// Check if Mac screen is locked by detecting loginwindow overlays
/// Usage: swift check_locked.swift  (prints LOCKED or UNLOCKED)
import Foundation
import CoreGraphics

let windowList = CGWindowListCopyWindowInfo(
    [.optionOnScreenOnly, .optionOnScreenAboveWindow],
    kCGNullWindowID
) as? [[String: Any]] ?? []

for win in windowList {
    let owner = win["kCGWindowOwnerName"] as? String ?? ""
    let layer = win["kCGWindowLayer"] as? Int ?? 0
    if owner == "loginwindow" && layer > 2000 {
        print("LOCKED")
        Foundation.exit(0)
    }
}
print("UNLOCKED")
