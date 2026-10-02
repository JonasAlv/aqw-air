# Windows GitHub Actions build

The `Build Windows app` workflow is manually triggered with `workflow_dispatch`.
It syncs gamefiles from the latest stable upstream APK, checks out the API's
`feat/enhancements` branch, compiles the API, UI, and SWF worker from source,
then packages a Windows AIR bundle and zips the preinstalled app folder. It
uses AIR SDK 51.3.1 through the maintained AIR setup action; no custom SDK URL
or checksum variables are required. The workflow is implemented with
PowerShell; local Bash scripts and gamefiles are not tracked. Android builds
remain local and are not part of this workflow.

The worker's `as3swf.swc` dependency is built from the pinned upstream
`claus/as3swf` source during CI, rather than downloaded as an unverified binary.

Each successful run uploads `aqw-mod-DD-MM-YYYY.zip` as a downloadable Actions
artifact, retained for 14 days. Extract the archive and launch the app
executable from the bundled folder; this avoids a separate AIR runtime
installation. CI creates a temporary self-signed certificate for packaging,
so Windows may show a publisher or SmartScreen warning. Use the project's
private release certificate for trusted public distribution; do not
distribute the temporary CI certificate.
