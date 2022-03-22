# Release checklist

| Step | RSI | RTR | RTS | SRF | SWI |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Edit Cartfile to point at tagged versions ||||||
| Run `make update` ||||||
| Verify that Cartfile.resolved only contains tagged versions ||||||
| Perform global diff with last release ||||||
| Submit what's new for translation ||||||
| Start git-flow release branch for new version ||||||
| Check version and build numbers. Bump if needed ||||||
| Update what's new JSON for betas ||||||
| Update what's new on Pastebin (mark new release with the _preprod_ flag) ||||||
| Create new version on App Store Connect with what's new information ||||||
| Collect translated what's new and update Pastbin and App Store Connect ||||||
| Update screenshots if needed (with fastlane) ||||||
| Build betas for AppCenter (with fastlane on TeamCity) ||||||
| Build versions for App Store Connect (with fastlane on TeamCity) ||||||
| Wait until the binary has been validated on App Store Connect ||||||
| Collect DSYMs and upload it on AppCenter (with fastlane) ||||||
| Update production remote configuration on Firebase ||||||
| Distribute TestFlight versions on App Store Connect ||||||
| Check what's new in AppCenter betas or TestFlight versions ||||||
| Ask the PO to approve the version ||||||
| Submit to Apple review ||||||
| Update status page on Confluence (Up coming status, statistics changes) ||||||
| Obtain successful Apple review ||||||
| Release to the store ||||||
| Check that the application is available in production ||||||
| Remove the _preprod_ flag from what's new information on Pastebin ||||||
| Check what's new information with production applications ||||||
| Finish git-flow release ||||||
| Bump patch / build version numbers in project ||||||
| Push master, develop and tag ||||||
| Close milestone and issues on github |||||||||||||||
| Create github release |||||||||||||||
| Update status page on Confluence (Release date, old versions) ||||||
| Update AppCenter beta release notes to highlight the beta version corresponding to the production version ||||||
