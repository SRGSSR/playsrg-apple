# Release checklist

| Step | RSI | RTR | RTS | SRF | SWI |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Edit Cartfile to point at tagged versions ||||||
| Run `make update` ||||||
| Verify that Cartfile.resolved only contains tagged versions ||||||
| Perform global diff with last release ||||||
| Submit what's new for translation ||||||
| Collect translated what's new ||||||
| Start git-flow release branch for new version ||||||
| Check version and build numbers. Bump if needed ||||||
| Update what's new JSON ||||||
| Update what's new on Pastebin (mark new release with the _preprod_ flag) ||||||
| Create new version on iTunes Connect with what's new information ||||||
| Update screenshots if needed ||||||
| Build betas for HockeyApp ||||||
| Check what's new in HockeyApp betas ||||||
| Write test ticket and alert testers on Slack ||||||
| Build versions for iTunes Connect ||||||
| Wait until the binary has been validated on iTunes Connect ||||||
| Get the binary DSYM and upload it on HockeyApp ||||||
| Ask the BU to approve the version ||||||
| Wait until successful Apple review ||||||
| Release to the store ||||||
| Check that the application is available in production ||||||
| Remove the _preprod_ flag from what's new information on Pastebin ||||||
| Check what's new information with production applications ||||||
| Finish git-flow release ||||||
| Bump patch / build version numbers in project ||||||
| Push master, develop and tag ||||||
| Close milestone and issues on github |||||||||||||||
| Create github release |||||||||||||||
| Update status page on Confluence ||||||
| Update Hockey beta release notes highlight the beta version corresponding to the production version ||||||
