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
### ios iOSappStoreUploads
```
fastlane ios iOSappStoreUploads
```
Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSdSYMs
```
fastlane ios iOSdSYMs
```
Sends latest iOS AppStore dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
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
### ios iOSswiScreenshots
```
fastlane ios iOSswiScreenshots
```
SWI: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSsrfScreenshots
```
fastlane ios iOSsrfScreenshots
```
SRF: Makes iOS screenshots.
### ios iOSrtsScreenshots
```
fastlane ios iOSrtsScreenshots
```
RTS: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSrsiScreenshots
```
fastlane ios iOSrsiScreenshots
```
RSI: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSrtrScreenshots
```
fastlane ios iOSrtrScreenshots
```
RTR: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSswiAppStoreUpload
```
fastlane ios iOSswiAppStoreUpload
```
SWI: Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSsrfAppStoreUpload
```
fastlane ios iOSsrfAppStoreUpload
```
SRF: Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSrtsAppStoreUpload
```
fastlane ios iOSrtsAppStoreUpload
```
RTS: Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSrsiAppStoreUpload
```
fastlane ios iOSrsiAppStoreUpload
```
RSI: Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSrtrAppStoreUpload
```
fastlane ios iOSrtrAppStoreUpload
```
RTR: Uploads a new iOS AppStore build on AppStore Connect with the current build number.
### ios iOSswiDSYMs
```
fastlane ios iOSswiDSYMs
```
SWI: Sends latest iOS AppStore dSYMs to App Center, with same parameters as 'dSYMs'.
### ios iOSsrfDSYMs
```
fastlane ios iOSsrfDSYMs
```
SFR: Sends latest iOS AppStore dSYMs to App Center, with same parameters as 'dSYMs'.
### ios iOSrtsDSYMs
```
fastlane ios iOSrtsDSYMs
```
RTS: Sends latest iOS AppStore dSYMs to App Center, with same parameters as 'dSYMs'.
### ios iOSrsiDSYMs
```
fastlane ios iOSrsiDSYMs
```
RSI: Sends latest iOS AppStore dSYMs to App Center, with same parameters as 'dSYMs'.
### ios iOSrtrDSYMs
```
fastlane ios iOSrtrDSYMs
```
RTR: Sends latest iOS AppStore dSYMs to App Center, with same parameters as 'dSYMs'.
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
