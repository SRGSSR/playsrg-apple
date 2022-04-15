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
| Distribute public TestFlight versions (with fastane\*\*) ||||||
| Check what's new in betas or TestFlight versions ||||||
| Ask the PO to approve the version ||||||
| Submit to Apple review ||||||
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

- Beta with current version number
	- iOS: `bundle exec fastlane ios iOSbetas`
	- tvOS: `bundle exec fastlane ios tvOSbetas`
- App Store build with current version number
	- iOS: `bundle exec fastlane ios iOSAppStoreBetas`
	- tvOS: `bundle exec fastlane ios tvOSAppStoreBetas`

### \*\*Manual fastlane:

- Screenshots
	- iOS: `iOSrsiScreenshots`, `iOSrtrScreenshots`, `iOSrtsScreenshots`, `iOSsrfScreenshots` (No upload to ASC, due to some marketing images), `iOSswiScreenshots`
	- tvOS: `tvOSrsiScreenshots`, `tvOSrtrScreenshots`, `tvOSrtsScreenshots`, `tvOSsrfScreenshots`, `tvOSswiScreenshots`
- Distribute public TestFlight from App Store build
	- iOS: `bundle exec fastlane ios iOSAppStoreDistributePublicBetas tag_version:3.6.0-382` (`tag_version` is optional. By default: the current local version) 
	- tvOS: `bundle exec fastlane ios tvOSAppStoreDistributePublicBetas tag_version:1.6.0-36` (`tag_version` is optional. By default: the current local version) 