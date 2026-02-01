/// Click at screen coordinates via CGEvent (works when screen is unlocked)
/// Usage: swift tap.swift <x> <y>
import Foundation
import CoreGraphics

guard CommandLine.arguments.count >= 3,
      let x = Double(CommandLine.arguments[1]),
      let y = Double(CommandLine.arguments[2]) else {
    print("Usage: tap <x> <y>")
    Foundation.exit(1)
}

let point = CGPoint(x: x, y: y)

// Move
let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                        mouseCursorPosition: point, mouseButton: .left)!
moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
usleep(100_000)

// Click down
let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                        mouseCursorPosition: point, mouseButton: .left)!
downEvent.post(tap: CGEventTapLocation.cghidEventTap)
usleep(50_000)

// Click up
let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                      mouseCursorPosition: point, mouseButton: .left)!
upEvent.post(tap: CGEventTapLocation.cghidEventTap)

print("Tapped at \(x), \(y)")
