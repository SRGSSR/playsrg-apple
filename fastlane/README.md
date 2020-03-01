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
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios nightlies
```
fastlane ios nightlies
```
For each BUs, build a new nightly on App Center, with a new build number, greater than the old nightly build number
### ios betas
```
fastlane ios betas
```
For each BUs, build a new beta on App Center with the current build number. If we're not in a release or hotfix process (master, release/* or hotfix/*), tag the current version on the repository and bump the build number
### ios swiAppStoreUpload
```
fastlane ios swiAppStoreUpload
```
SWI: Upload a new build (bitcode) on AppStore Connect with the current build number.
### ios srfAppStoreUpload
```
fastlane ios srfAppStoreUpload
```
SRF: Upload a new build (bitcode) on AppStore Connect with the current build number.
### ios rtsAppStoreUpload
```
fastlane ios rtsAppStoreUpload
```
RTS: Upload a new build (bitcode) on AppStore Connect with the current build number.
### ios rsiAppStoreUpload
```
fastlane ios rsiAppStoreUpload
```
RSI: Upload a new build (bitcode) on AppStore Connect with the current build number.
### ios rtrAppStoreUpload
```
fastlane ios rtrAppStoreUpload
```
RTR: Upload a new build (bitcode) on AppStore Connect with the current build number.
### ios dSYMs
```
fastlane ios dSYMs
```
Send latest dSYMs to App Center. Optional 'version' or 'min_version' parameters.
### ios swiDSYMs
```
fastlane ios swiDSYMs
```
SWI: Send latest dSYMs to App Center, with same parameters.
### ios srfDSYMs
```
fastlane ios srfDSYMs
```
SFR: Send latest dSYMs to App Center, with same parameters.
### ios rtsDSYMs
```
fastlane ios rtsDSYMs
```
RTS: Send latest dSYMs to App Center, with same parameters.
### ios rsiDSYMs
```
fastlane ios rsiDSYMs
```
RSI: Send latest dSYMs to App Center, with same parameters.
### ios rtrDSYMs
```
fastlane ios rtrDSYMs
```
RTR: Send latest dSYMs to App Center, with same parameters.
### ios swiScreenshots
```
fastlane ios swiScreenshots
```
SWI: Make screenshots.
### ios srfScreenshots
```
fastlane ios srfScreenshots
```
SRF: Make screenshots.
### ios rtsScreenshots
```
fastlane ios rtsScreenshots
```
RTS: Make screenshots.
### ios rsiScreenshots
```
fastlane ios rsiScreenshots
```
RSI: Make screenshots.
### ios rtrScreenshots
```
fastlane ios rtrScreenshots
```
RTR: Make screenshots.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
