---
name: ios-simulator-testing
description: Test and automate iOS Simulator apps without screen access. Use when the Mac is locked/headless, or when you need to drive a Flutter app on the iOS Simulator via CLI—screenshots, API testing, photo injection, batch workflows. Covers simctl commands, display-sleep detection, coordinate clicking, Flutter debug mode, and auth token extraction.
---

# iOS Simulator Testing (Headless / Locked Mac)

## Core Constraint

When the Mac is **locked or headless**, `loginwindow` overlays (layer 2001/2004) block all mouse/keyboard events. **Do NOT waste time on UI clicking.** Go straight to CLI/API approaches.

## Quick Detection: Is the Screen Locked?

```bash
# Compile once, reuse
cat > /tmp/windowat.swift << 'SWIFT'
import Foundation
import CoreGraphics
let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .optionOnScreenAboveWindow], kCGNullWindowID) as? [[String: Any]] ?? []
for win in windowList {
    let owner = win["kCGWindowOwnerName"] as? String ?? ""
    let layer = win["kCGWindowLayer"] as? Int ?? 0
    if owner == "loginwindow" && layer > 2000 {
        print("LOCKED")
        Foundation.exit(0)
    }
}
print("UNLOCKED")
SWIFT
swiftc /tmp/windowat.swift -o /tmp/windowat 2>&1 && /tmp/windowat
```

If `LOCKED` → skip all peekaboo/CGEvent clicking; use simctl + API only.

## Simulator Basics

### List booted devices
```bash
xcrun simctl list devices booted -j | python3 -c "
import json,sys
for rt,devs in json.loads(sys.stdin.read())['devices'].items():
    for d in devs:
        if d['state']=='Booted': print(f\"{d['name']}: {d['udid']}\")
"
```

### Screenshot (always works, even locked)
```bash
xcrun simctl io <UDID> screenshot /tmp/sim.png
# Or use 'booted' — but with multiple devices, specify UDID
```

### Launch / terminate apps
```bash
xcrun simctl launch <UDID> <bundle-id>
xcrun simctl terminate <UDID> <bundle-id>
```

### Find bundle ID
```bash
xcrun simctl listapps <UDID> 2>/dev/null | grep CFBundleIdentifier | sort -u
```

### Add photos to simulator library
```bash
xcrun simctl addmedia <UDID> photo1.jpg photo2.jpg
```

### Photo library location
```
~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Media/DCIM/100APPLE/
```

## When Screen is UNLOCKED: UI Automation

### Peekaboo (preferred)
```bash
peekaboo see --app Simulator --annotate --path /tmp/sim-see.png
peekaboo click --on elem_27 --app Simulator
```

**Caveat:** Peekaboo may return 0 elements for Simulator content or time out. If that happens, fall back to coordinate clicking.

### Coordinate clicking (Swift CGEvent)
```bash
# Compile a reusable tap tool
cat > /tmp/tap.swift << 'SWIFT'
import Foundation, CoreGraphics
let x = Double(CommandLine.arguments[1])!
let y = Double(CommandLine.arguments[2])!
let point = CGPoint(x: x, y: y)
let m = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!
m.post(tap: CGEventTapLocation.cghidEventTap)
usleep(100000)
let d = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)!
d.post(tap: CGEventTapLocation.cghidEventTap)
usleep(50000)
let u = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)!
u.post(tap: CGEventTapLocation.cghidEventTap)
print("Tapped at \(x), \(y)")
SWIFT
swiftc /tmp/tap.swift -o /tmp/tap && /tmp/tap 1688 968
```

### Finding window coordinates
```bash
peekaboo list windows --app Simulator --json > /tmp/w.json
python3 -c "
import json
for w in json.load(open('/tmp/w.json'))['data']['windows']:
    t=w.get('title',''); b=w.get('bounds','')
    if 'iPhone' in t: print(f'{t}: origin={b[0]} size={b[1]}')
"
```

iOS screen maps to window content area (minus ~22px title bar). iPhone 16 Pro logical: 393×852pt.

### Wake display (if asleep but not locked)
```bash
caffeinate -u -t 5
```

## Flutter Debug Mode: VM Service Control

When the app needs **programmatic navigation** without UI clicking.

### Launch in debug mode
```bash
cd <flutter-project>
flutter run -d <UDID> --no-pub
# Outputs: A Dart VM Service on iPhone 16 Pro is available at: http://127.0.0.1:<port>/<token>=/
```

**Hot reload:** send `r` to stdin. **Hot restart:** send `R`.

### Important rule
**Never modify the project's existing source code for testing.** Only create standalone test files (integration tests, scripts).

## API-Level Testing (Best for Locked Mac)

The most reliable approach when the screen is locked. Directly call the app's backend APIs.

### Extract auth token from simulator
```bash
# Flutter apps using Supabase store tokens in UserDefaults
PLIST="<app-container>/Library/Preferences/<bundle-id>.plist"

# Find container path
CONTAINER=$(xcrun simctl get_app_container <UDID> <bundle-id> data)

# Extract token
plutil -p "$PLIST" | python3 -c "
import sys, json, re
text = sys.stdin.read()
match = re.search(r'\"flutter\.sb-.*?auth-token\" => \"(.+?)\"$', text, re.MULTILINE | re.DOTALL)
if match:
    data = json.loads(match.group(1))
    print(data['access_token'])
"
```

**Note:** The `plutil -extract` command fails on keys with dots. Use `plutil -p` + regex instead.

### API test pattern
```bash
TOKEN="<extracted-token>"
API="http://localhost:4001"

# Health check
curl -s "$API/health"

# Authenticated request
curl -s "$API/api/v1/endpoint" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# File upload (multipart)
curl -s -X POST "$API/api/v1/storage/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/image.jpg" \
  -F "path=target/storage/path.jpg"
```

## Gotchas & Lessons Learned

| Issue | Cause | Solution |
|-------|-------|----------|
| peekaboo click reports `loginwindow` | Mac screen locked; loginwindow overlays at layer 2001+ | Use simctl/API instead |
| peekaboo see returns 0 elements | Simulator content not exposed via macOS accessibility | Use simctl screenshot + image analysis |
| `screencapture` not found | Not in PATH on some setups | Use `peekaboo image` or `xcrun simctl io screenshot` |
| `CGWindowListCreateImage` error | Deprecated in macOS 15+; use ScreenCaptureKit | Use `xcrun simctl io screenshot` instead |
| `plutil -extract` fails on dotted keys | Dots interpreted as key path separators | Use `plutil -p` (pretty print) + regex |
| Hot reload doesn't change widget state | StatefulWidget preserves state on hot reload | Use hot restart (`R`) for state-dependent changes |
| Display asleep vs locked | `caffeinate -u` wakes display but loginwindow stays | Must unlock to interact with UI; use API for locked |
| Multiple booted simulators | `xcrun simctl io booted` picks arbitrary device | Always specify UDID explicitly |
| App container path changes on rebuild | New container UUID each install | Always use `xcrun simctl get_app_container` dynamically |

## Reference: See Also

- `references/batch-test-example.sh` — Complete batch API test script
