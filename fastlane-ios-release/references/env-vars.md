# Environment Variables (do NOT commit secrets)

## Locale (fastlane docs recommend UTF-8)

```bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

## App Store Connect auth (preferred: API key)

Use fastlane App Store Connect API key (pilot/deliver support it):
- `key_id`
- `issuer_id`
- `key_filepath` (path to `.p8` file)

Store these in a local secret store or CI secrets. Do not commit.

## match passphrase

If using match with git storage:

```bash
export MATCH_PASSWORD="<passphrase>"
```

## Apple ID fallback

If using Apple ID auth (not preferred), you may need:
- `FASTLANE_USER`
- `FASTLANE_PASSWORD` (avoid if possible)
- Application-specific password in some flows:
  `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`

Prefer API key to avoid 2FA.
