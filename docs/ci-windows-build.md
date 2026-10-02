# Windows GitHub Actions build

The `Build Windows app` workflow runs on pushes and pull requests to
`feat/enhancements`, or on demand. It syncs gamefiles from the latest stable
upstream APK, checks out the API's `feat/enhancements` branch, compiles the API,
UI, and SWF worker from source, then packages a Windows AIR installer. The
workflow is implemented with PowerShell; local Bash scripts and gamefiles are
not tracked. Android builds remain local and are not part of this workflow.

The worker's `as3swf.swc` dependency is built from the pinned upstream
`claus/as3swf` source during CI, rather than downloaded as an unverified binary.

Configure these repository variables under **Settings → Secrets and variables
→ Actions → Variables**:

- `AIR_SDK_WINDOWS_URL`: HTTPS URL for the Windows AIR SDK ZIP used by this
  project (AIR 51.3 or a compatible version).
- `AIR_SDK_WINDOWS_SHA256`: SHA-256 digest of that exact ZIP.

The workflow verifies the SDK archive before extraction. The downloaded
`AQW-Pocket-Windows.exe` is a CI build artifact available for 14 days. CI
creates a temporary self-signed certificate for packaging, so Windows may show
a publisher or SmartScreen warning. Use the project's private release
certificate and protected secrets for trusted public releases; do not use the
temporary CI certificate for distribution.
