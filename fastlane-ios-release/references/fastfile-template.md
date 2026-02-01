# Fastfile Template (Safe lanes)

> Copy/edit into `fastlane/Fastfile`.
> Keep side-effecting lanes separate.

```ruby
default_platform(:ios)

platform :ios do
  before_all do
    # Avoid metrics if desired
    # opt_out_usage
  end

  desc "Preflight checks: tests + git clean"
  lane :verify do
    ensure_git_status_clean
    # Optional: ensure version/build numbers are set
    # increment_build_number(xcodeproj: "YourApp.xcodeproj")

    # Run unit/UI tests (scan)
    # scan(
    #   workspace: "YourApp.xcworkspace",
    #   scheme: "YourApp",
    #   configuration: "Debug"
    # )
  end

  desc "Sync signing + build IPA"
  lane :build do
    # Code signing (match)
    match(type: "appstore")

    build_app(
      workspace: "YourApp.xcworkspace",
      scheme: "YourApp",
      configuration: "Release",
      export_method: "app-store"
    )
  end

  desc "Upload to TestFlight"
  lane :beta do
    verify
    build

    upload_to_testflight(
      skip_submission: true,
      # changelog: "..."
    )
  end

  desc "Upload metadata/screenshots/binary to App Store"
  lane :release do
    verify
    build

    # Safer default: upload but do NOT submit automatically
    deliver(
      force: true,
      submit_for_review: false
    )

    # Only enable after explicit confirmation:
    # deliver(submit_for_review: true, force: true)
  end

  error do |lane, exception|
    UI.error("Lane #{lane} failed: #{exception}")
  end
end
```
