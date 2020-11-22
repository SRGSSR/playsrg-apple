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
Build a new iOS nightly on App Center
### ios tvOSnightlies
```
fastlane ios tvOSnightlies
```
Build a new tvOS nightly on AppStore Connect and wait build processing.
### ios betas
```
fastlane ios betas
```
Build a new iOS beta on App Center with the current build number. If we're not in a release or hotfix process (master, release/* or hotfix/*), tag the current version on the repository and bump the build number
### ios tvOSbetas
```
fastlane ios tvOSbetas
```
Build a new tvOS beta on AppStore Connect with the current build number and wait build processing. If we're not in a release or hotfix process (master, release/* or hotfix/*), tag the current version on the repository and bump the build number
### ios appStoreUploads
```
fastlane ios appStoreUploads
```
Upload a new iOS build on AppStore Connect with the current build number.
### ios swiAppStoreUpload
```
fastlane ios swiAppStoreUpload
```
SWI: Upload a new iOS build on AppStore Connect with the current build number.
### ios srfAppStoreUpload
```
fastlane ios srfAppStoreUpload
```
SRF: Upload a new iOS build on AppStore Connect with the current build number.
### ios rtsAppStoreUpload
```
fastlane ios rtsAppStoreUpload
```
RTS: Upload a new iOS build on AppStore Connect with the current build number.
### ios rsiAppStoreUpload
```
fastlane ios rsiAppStoreUpload
```
RSI: Upload a new iOS build on AppStore Connect with the current build number.
### ios rtrAppStoreUpload
```
fastlane ios rtrAppStoreUpload
```
RTR: Upload a new iOS build on AppStore Connect with the current build number.
### ios dSYMs
```
fastlane ios dSYMs
```
Send latest iOS dSYMs to App Center. Optional 'version' or 'min_version' parameters.
### ios swiDSYMs
```
fastlane ios swiDSYMs
```
SWI: Send latest iOS dSYMs to App Center, with same parameters.
### ios srfDSYMs
```
fastlane ios srfDSYMs
```
SFR: Send latest iOS dSYMs to App Center, with same parameters.
### ios rtsDSYMs
```
fastlane ios rtsDSYMs
```
RTS: Send latest iOS dSYMs to App Center, with same parameters.
### ios rsiDSYMs
```
fastlane ios rsiDSYMs
```
RSI: Send latest iOS dSYMs to App Center, with same parameters.
### ios rtrDSYMs
```
fastlane ios rtrDSYMs
```
RTR: Send latest iOS dSYMs to App Center, with same parameters.
### ios swiScreenshots
```
fastlane ios swiScreenshots
```
SWI: Make iOS screenshots and overwrite on AppStoreConnect.
### ios srfScreenshots
```
fastlane ios srfScreenshots
```
SRF: Make iOS screenshots and overwrite on AppStoreConnect.
### ios rtsScreenshots
```
fastlane ios rtsScreenshots
```
RTS: Make iOS screenshots and overwrite on AppStoreConnect.
### ios rsiScreenshots
```
fastlane ios rsiScreenshots
```
RSI: Make iOS screenshots and overwrite on AppStoreConnect.
### ios rtrScreenshots
```
fastlane ios rtrScreenshots
```
RTR: Make iOS screenshots and overwrite on AppStoreConnect.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
