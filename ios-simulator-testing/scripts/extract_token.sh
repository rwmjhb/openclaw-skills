#!/bin/bash
# Extract Supabase auth token from iOS Simulator app's UserDefaults
# Usage: extract_token.sh <UDID> <bundle-id>
# Example: extract_token.sh E083B1B9-... com.skinguardian.app

UDID="${1:?Usage: extract_token.sh <UDID> <bundle-id>}"
BUNDLE_ID="${2:?Usage: extract_token.sh <UDID> <bundle-id>}"

CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data 2>/dev/null)
if [ -z "$CONTAINER" ]; then
  echo "ERROR: Cannot find app container for $BUNDLE_ID on $UDID" >&2
  exit 1
fi

PLIST="$CONTAINER/Library/Preferences/$BUNDLE_ID.plist"
if [ ! -f "$PLIST" ]; then
  echo "ERROR: Plist not found: $PLIST" >&2
  exit 1
fi

TOKEN=$(plutil -p "$PLIST" 2>/dev/null | python3 -c "
import sys, json, re
text = sys.stdin.read()
match = re.search(r'\"flutter\.sb-.*?auth-token\" => \"(.+?)\"$', text, re.MULTILINE | re.DOTALL)
if match:
    data = json.loads(match.group(1))
    print(data['access_token'])
else:
    print('', end='')
")

if [ -z "$TOKEN" ]; then
  echo "ERROR: No auth token found in plist" >&2
  exit 1
fi

echo "$TOKEN"
