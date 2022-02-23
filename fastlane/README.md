fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios nightlies
```
fastlane ios nightlies
```
Builds a new iOS nightly on App Center.
### ios tvOSnightlies
```
fastlane ios tvOSnightlies
```
Builds a new tvOS nightly on AppStore Connect and waits build processing.
### ios tvOSnightlyDSYMs
```
fastlane ios tvOSnightlyDSYMs
```
Sends latest tvOS nightly dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios iOSnightlies
```
fastlane ios iOSnightlies
```
Builds a new iOS nightly on AppStore Connect and waits build processing.
### ios iOSnightlyDSYMs
```
fastlane ios iOSnightlyDSYMs
```
Sends latest iOS nightly dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios nightlyTester
```
fastlane ios nightlyTester
```
Add a nightly TestFlight tester (email required)
### ios betas
```
fastlane ios betas
```
Builds a new iOS beta on App Center with the current build number. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
### ios tvOSbetas
```
fastlane ios tvOSbetas
```
Builds a new tvOS beta on AppStore Connect with the current build number and waits build processing. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
### ios tvOSbetaDSYMs
```
fastlane ios tvOSbetaDSYMs
```
Sends latest tvOS beta dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios iOSbetas
```
fastlane ios iOSbetas
```
Builds a new iOS beta on AppStore Connect with the current build number and waits build processing. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
### ios iOSbetaDSYMs
```
fastlane ios iOSbetaDSYMs
```
Sends latest iOS beta dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios betaTester
```
fastlane ios betaTester
```
Add a beta TestFlight tester (email required)
### ios appStoreUploads
```
fastlane ios appStoreUploads
```
Uploads a new iOS build on AppStore Connect with the current build number.
### ios dSYMs
```
fastlane ios dSYMs
```
Sends latest iOS dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios tvOSappStoreUploads
```
fastlane ios tvOSappStoreUploads
```
Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSdSYMs
```
fastlane ios tvOSdSYMs
```
Sends latest tvOS dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios swiScreenshots
```
fastlane ios swiScreenshots
```
SWI: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios srfScreenshots
```
fastlane ios srfScreenshots
```
SRF: Makes iOS screenshots.
### ios rtsScreenshots
```
fastlane ios rtsScreenshots
```
RTS: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios rsiScreenshots
```
fastlane ios rsiScreenshots
```
RSI: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios rtrScreenshots
```
fastlane ios rtrScreenshots
```
RTR: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios swiAppStoreUpload
```
fastlane ios swiAppStoreUpload
```
SWI: Uploads a new iOS build on AppStore Connect with the current build number.
### ios srfAppStoreUpload
```
fastlane ios srfAppStoreUpload
```
SRF: Uploads a new iOS build on AppStore Connect with the current build number.
### ios rtsAppStoreUpload
```
fastlane ios rtsAppStoreUpload
```
RTS: Uploads a new iOS build on AppStore Connect with the current build number.
### ios rsiAppStoreUpload
```
fastlane ios rsiAppStoreUpload
```
RSI: Uploads a new iOS build on AppStore Connect with the current build number.
### ios rtrAppStoreUpload
```
fastlane ios rtrAppStoreUpload
```
RTR: Uploads a new iOS build on AppStore Connect with the current build number.
### ios swiDSYMs
```
fastlane ios swiDSYMs
```
SWI: Sends latest iOS dSYMs to App Center, with same parameters as 'dSYMs'.
### ios srfDSYMs
```
fastlane ios srfDSYMs
```
SFR: Sends latest iOS dSYMs to App Center, with same parameters as 'dSYMs'.
### ios rtsDSYMs
```
fastlane ios rtsDSYMs
```
RTS: Sends latest iOS dSYMs to App Center, with same parameters as 'dSYMs'.
### ios rsiDSYMs
```
fastlane ios rsiDSYMs
```
RSI: Sends latest iOS dSYMs to App Center, with same parameters as 'dSYMs'.
### ios rtrDSYMs
```
fastlane ios rtrDSYMs
```
RTR: Sends latest iOS dSYMs to App Center, with same parameters as 'dSYMs'.
### ios tvOSswiScreenshots
```
fastlane ios tvOSswiScreenshots
```
SWI: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSsrfScreenshots
```
fastlane ios tvOSsrfScreenshots
```
SRF: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSrtsScreenshots
```
fastlane ios tvOSrtsScreenshots
```
RTS: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSrsiScreenshots
```
fastlane ios tvOSrsiScreenshots
```
RSI: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSrtrScreenshots
```
fastlane ios tvOSrtrScreenshots
```
RTR: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSswiAppStoreUpload
```
fastlane ios tvOSswiAppStoreUpload
```
SWI: Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSsrfAppStoreUpload
```
fastlane ios tvOSsrfAppStoreUpload
```
SRF: Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSrtsAppStoreUpload
```
fastlane ios tvOSrtsAppStoreUpload
```
RTS: Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSrsiAppStoreUpload
```
fastlane ios tvOSrsiAppStoreUpload
```
RSI: Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSrtrAppStoreUpload
```
fastlane ios tvOSrtrAppStoreUpload
```
RTR: Uploads a new tvOS build on AppStore Connect with the current build number.
### ios tvOSswiDSYMs
```
fastlane ios tvOSswiDSYMs
```
SWI: Sends latest tvOS dSYMs to App Center, with same parameters as 'tvOSdSYMs'.
### ios tvOSsrfDSYMs
```
fastlane ios tvOSsrfDSYMs
```
SFR: Sends latest tvOS dSYMs to App Center, with same parameters as 'tvOSdSYMs'.
### ios tvOSrtsDSYMs
```
fastlane ios tvOSrtsDSYMs
```
RTS: Sends latest tvOS dSYMs to App Center, with same parameters as 'tvOSdSYMs'.
### ios tvOSrsiDSYMs
```
fastlane ios tvOSrsiDSYMs
```
RSI: Sends latest tvOS dSYMs to App Center, with same parameters as 'tvOSdSYMs'.
### ios tvOSrtrDSYMs
```
fastlane ios tvOSrtrDSYMs
```
RTR: Sends latest tvOS dSYMs to App Center, with same parameters as 'tvOSdSYMs'.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
