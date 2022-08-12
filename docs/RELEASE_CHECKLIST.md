# Release checklist

| Step | RSI | RTR | RTS | SRF | SWI |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Edit SPM / Podfile dependencies to point at tagged versions ||||||
| Verify that Package.resolved / Podfile.lock only contain tagged versions ||||||
| Update application translations (with pullCrowdin .sh) ||||||
| Perform global diff with last release ||||||
| Submit what's new for translation ||||||
| Start git-flow release branch for new version ||||||
| Check version and build numbers. Bump if needed ||||||
| Update what's new JSON for betas ||||||
| [iOS] Update what's new on Pastebin (mark new release with the preprod flag) ||||||
| Create new version on App Store Connect with what's new information ||||||
| Collect translated what's new and update App Store Connect ||||||
| [iOS] Collect translated what's new and update Pastebin ||||||
| Update screenshots if needed (with fastlane\*\*) ||||||
| Build betas for TestFlight (with fastlane\*) ||||||
| Build App Store versions + collect DSYMs (with fastlane\*) ||||||
| Update production remote configuration on Firebase ||||||
| Distribute public TestFlight versions (with fastane\*) ||||||
| Check what's new in betas or TestFlight versions ||||||
| Ask the PO to approve the version ||||||
| Submit to Apple review (with fastlane\*) ||||||
| Update status page on Confluence (Up coming status, statistics changes) ||||||
| Obtain successful Apple review ||||||
| Release to the store ||||||
| [iOS] Remove the preprod flag from what's new information on Pastebin ||||||
| [iOS] Check what's new information with production applications ||||||
| Finish git-flow release ||||||
| Bump patch / build version numbers in project ||||||
| Push master, develop and tag ||||||
| Close milestone and issues on github ||||||
| Create github release ||||||
| Update status page on Confluence (Release date, old versions section) ||||||

### \*Fastlane on PlayCity CI:

- Build Betas with current version number
	- **Play SRG iOS Betas**: `fastlane ios iOSbetas`
	- **Play SRG tvOS Betas**: `fastlane ios tvOSbetas`
- Build App Store builds with current version number
	- **Play SRG iOS AppStore builds**: `fastlane ios iOSAppStoreBuilds`
	- **Play SRG tvOS AppStore builds**: `fastlane ios tvOSAppStoreBuilds`
- Distribute App Store builds to public TestFlight with the current version number
	- **Play SRG iOS AppStore builds** (with `true` to `public_testflight_distribution` parameter): `fastlane ios iOSAppStoreBuilds public_testflight_distribution:true`
	- **Play SRG tvOS AppStore builds** (with `true` to `public_testflight_distribution` parameter): `fastlane ios tvOSAppStoreBuilds public_testflight_distribution:true`
- Prepare AppStore releases on AppStore Connect with the current version number
	- **Play SRG iOS AppStore releases**: `fastlane ios iOSPrepareAppStoreReleases`
	- **Play SRG tvOS AppStore releases**: `fastlane ios tvOSPrepareAppStoreReleases`
- Submit to Apple review the releases with the current version number
	- **Play SRG iOS AppStore releases** (with `true` to `submit_for_review` parameter): `fastlane ios tvOSPrepareAppStoreReleases submit_for_review:true`
	- **Play SRG tvOS AppStore releases** (with `true` to `submit_for_review` parameter):  `fastlane ios tvOSPrepareAppStoreReleases submit_for_review:true`

### \*\*Manual fastlane:

- Screenshots iOS
	- Play RSI iOS: `fastlane ios iOSrsiScreenshots`
	- Play RTR iOS: `fastlane ios iOSrtrScreenshots`
	- Play RTS iOS: `fastlane ios iOSrtsScreenshots`
	- Play SRF iOS: `fastlane ios iOSsrfScreenshots` (No upload to ASC, due to some marketing images)
	- Play SWI iOS: `fastlane ios iOSswiScreenshots`
- Screenshots tvOS
	- Play RSI tvOS: `fastlane ios tvOSrsiScreenshots`
	- Play RTR tvOS: `fastlane ios tvOSrtrScreenshots`
	- Play RTS tvOS: `fastlane ios tvOSrtsScreenshots`
	- Play SRF tvOS: `fastlane ios tvOSsrfScreenshots`
	- Play SWI tvOS: `fastlane ios tvOSswiScreenshots`