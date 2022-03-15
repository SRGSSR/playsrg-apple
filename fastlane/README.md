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
### ios appcenteriOSnighties
```
fastlane ios appcenteriOSnighties
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
### ios appcenteriOSbetas
```
fastlane ios appcenteriOSbetas
```
Builds an iOS beta on App Center with the current build number. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
### ios tvOSbetas
```
fastlane ios tvOSbetas
```
Builds a tvOS beta on AppStore Connect with the current build number and waits build processing. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
### ios tvOSbetaDSYMs
```
fastlane ios tvOSbetaDSYMs
```
Sends latest tvOS beta dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios iOSbetas
```
fastlane ios iOSbetas
```
Builds an iOS beta on AppStore Connect with the current build number and waits build processing. If on the develop branch, tries to tag the current version, then bumps the build number and pushes.
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
### ios iOSAppStoreBetas
```
fastlane ios iOSAppStoreBetas
```
Applies iOSAppStoreUploadBetas, iOSAppStoreDistributePrivateBetas and iOSAppStoreDSYMs.
### ios iOSAppStoreUploadBetas
```
fastlane ios iOSAppStoreUploadBetas
```
Uploads an iOS AppStore beta on AppStore Connect with the current build number.
### ios iOSAppStoreDistributePrivateBetas
```
fastlane ios iOSAppStoreDistributePrivateBetas
```
Distributes to private groups an iOS AppStore beta on AppStore Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).
### ios iOSAppStoreDistributePublicBetas
```
fastlane ios iOSAppStoreDistributePublicBetas
```
Distributes to public groups an iOS AppStore beta on AppStore Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).
### ios iOSAppStoreDSYMs
```
fastlane ios iOSAppStoreDSYMs
```
Sends latest iOS AppStore dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
### ios tvOSAppStoreBetas
```
fastlane ios tvOSAppStoreBetas
```
Applies tvOSAppStoreUploadBetas, tvOSAppStoreDistributePrivateBetas and tvOSAppStoreDSYMs.
### ios tvOSAppStoreUploadBetas
```
fastlane ios tvOSAppStoreUploadBetas
```
Uploads a tvOS build on AppStore Connect with the current build number.
### ios tvOSAppStoreDistributePrivateBetas
```
fastlane ios tvOSAppStoreDistributePrivateBetas
```
Distributes to private groups a tvOS AppStore beta on AppStore Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).
### ios tvOSAppStoreDistributePublicBetas
```
fastlane ios tvOSAppStoreDistributePublicBetas
```
Distributes to public groups a tvOS AppStore beta on AppStore Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).
### ios tvOSAppStoreDSYMs
```
fastlane ios tvOSAppStoreDSYMs
```
Sends latest tvOS dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.
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
### ios iOSrtsScreenshots
```
fastlane ios iOSrtsScreenshots
```
RTS: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSsrfScreenshots
```
fastlane ios iOSsrfScreenshots
```
SRF: Makes iOS screenshots. !!! No replacements on AppStoreConnect done !!!
### ios iOSswiScreenshots
```
fastlane ios iOSswiScreenshots
```
SWI: Makes iOS screenshots and replaces current ones on AppStoreConnect.
### ios iOSrsiAppStoreUploadBeta
```
fastlane ios iOSrsiAppStoreUploadBeta
```
RSI only: See 'iOSAppStoreUploadBetas' lane.
### ios iOSrtrAppStoreUploadBeta
```
fastlane ios iOSrtrAppStoreUploadBeta
```
RTR only: See 'iOSAppStoreUploadBetas' lane.
### ios iOSrtsAppStoreUploadBeta
```
fastlane ios iOSrtsAppStoreUploadBeta
```
RTS only: See 'iOSAppStoreUploadBetas' lane.
### ios iOSsrfAppStoreUploadBeta
```
fastlane ios iOSsrfAppStoreUploadBeta
```
SRF only: See 'iOSAppStoreUploadBetas' lane.
### ios iOSswiAppStoreUploadBeta
```
fastlane ios iOSswiAppStoreUploadBeta
```
SWI only: See 'iOSAppStoreUploadBetas' lane.
### ios iOSrsiAppStoreDistributePrivateBeta
```
fastlane ios iOSrsiAppStoreDistributePrivateBeta
```
RSI only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSrtrAppStoreDistributePrivateBeta
```
fastlane ios iOSrtrAppStoreDistributePrivateBeta
```
RTR only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSrtsAppStoreDistributePrivateBeta
```
fastlane ios iOSrtsAppStoreDistributePrivateBeta
```
RTS only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSsrfAppStoreDistributePrivateBeta
```
fastlane ios iOSsrfAppStoreDistributePrivateBeta
```
SRF only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSswiAppStoreDistributePrivateBeta
```
fastlane ios iOSswiAppStoreDistributePrivateBeta
```
SWI only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSrsiAppStoreDistributePublicBeta
```
fastlane ios iOSrsiAppStoreDistributePublicBeta
```
RSI only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSrtrAppStoreDistributePublicBeta
```
fastlane ios iOSrtrAppStoreDistributePublicBeta
```
RTR only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSrtsAppStoreDistributePublicBeta
```
fastlane ios iOSrtsAppStoreDistributePublicBeta
```
RTS only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSsrfAppStoreDistributePublicBeta
```
fastlane ios iOSsrfAppStoreDistributePublicBeta
```
SRF only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSswiAppStoreDistributePublicBeta
```
fastlane ios iOSswiAppStoreDistributePublicBeta
```
SWI only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSrsiAppStoreDSYMs
```
fastlane ios iOSrsiAppStoreDSYMs
```
RSI only: See 'iOSAppStoreDSYMs' lane.
### ios iOSrtrAppStoreDSYMs
```
fastlane ios iOSrtrAppStoreDSYMs
```
RTR only: See 'iOSAppStoreDSYMs' lane.
### ios iOSrtsAppStoreDSYMs
```
fastlane ios iOSrtsAppStoreDSYMs
```
RTS only: See 'iOSAppStoreDSYMs' lane.
### ios iOSsrfAppStoreDSYMs
```
fastlane ios iOSsrfAppStoreDSYMs
```
SFR only: See 'iOSAppStoreDSYMs' lane.
### ios iOSswiAppStoreDSYMs
```
fastlane ios iOSswiAppStoreDSYMs
```
SWI only: See 'iOSAppStoreDSYMs' lane.
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
### ios tvOSrtsScreenshots
```
fastlane ios tvOSrtsScreenshots
```
RTS: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSsrfScreenshots
```
fastlane ios tvOSsrfScreenshots
```
SRF: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSswiScreenshots
```
fastlane ios tvOSswiScreenshots
```
SWI: Makes tvOS screenshots and replaces current ones on AppStoreConnect.
### ios tvOSrsiAppStoreUploadBeta
```
fastlane ios tvOSrsiAppStoreUploadBeta
```
RSI only: See 'tvOSAppStoreUploadBetas' lane.
### ios tvOSrtrAppStoreUploadBeta
```
fastlane ios tvOSrtrAppStoreUploadBeta
```
RTR only: See 'tvOSAppStoreUploadBetas' lane.
### ios tvOSrtsAppStoreUploadBeta
```
fastlane ios tvOSrtsAppStoreUploadBeta
```
RTS only: See 'tvOSAppStoreUploadBetas' lane.
### ios tvOSsrfAppStoreUploadBeta
```
fastlane ios tvOSsrfAppStoreUploadBeta
```
SRF only: See 'tvOSAppStoreUploadBetas' lane.
### ios tvOSswiAppStoreUploadBeta
```
fastlane ios tvOSswiAppStoreUploadBeta
```
SWI only: See 'tvOSAppStoreUploadBetas' lane.
### ios tvOSrsiAppStoreDistributePrivateBeta
```
fastlane ios tvOSrsiAppStoreDistributePrivateBeta
```
RSI only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSrtrAppStoreDistributePrivateBeta
```
fastlane ios tvOSrtrAppStoreDistributePrivateBeta
```
RTR only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSrtsAppStoreDistributePrivateBeta
```
fastlane ios tvOSrtsAppStoreDistributePrivateBeta
```
RTS only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSsrfAppStoreDistributePrivateBeta
```
fastlane ios tvOSsrfAppStoreDistributePrivateBeta
```
SRF only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSswiAppStoreDistributePrivateBeta
```
fastlane ios tvOSswiAppStoreDistributePrivateBeta
```
SWI only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSrsiAppStoreDistributePublicBeta
```
fastlane ios tvOSrsiAppStoreDistributePublicBeta
```
RSI only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSrtrAppStoreDistributePublicBeta
```
fastlane ios tvOSrtrAppStoreDistributePublicBeta
```
RTR only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSrtsAppStoreDistributePublicBeta
```
fastlane ios tvOSrtsAppStoreDistributePublicBeta
```
RTS only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSsrfAppStoreDistributePublicBeta
```
fastlane ios tvOSsrfAppStoreDistributePublicBeta
```
SRF only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSswiAppStoreDistributePublicBeta
```
fastlane ios tvOSswiAppStoreDistributePublicBeta
```
SWI only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSrsiAppStoreDSYMs
```
fastlane ios tvOSrsiAppStoreDSYMs
```
RSI only: See 'tvOSAppStoreDSYMs' lane.
### ios tvOSrtrAppStoreDSYMs
```
fastlane ios tvOSrtrAppStoreDSYMs
```
RTR only: See 'tvOSAppStoreDSYMs' lane.
### ios tvOSrtsAppStoreDSYMs
```
fastlane ios tvOSrtsAppStoreDSYMs
```
RTS only: See 'tvOSAppStoreDSYMs' lane.
### ios tvOSsrfAppStoreDSYMs
```
fastlane ios tvOSsrfAppStoreDSYMs
```
SFR only: See 'tvOSAppStoreDSYMs' lane.
### ios tvOSswiAppStoreDSYMs
```
fastlane ios tvOSswiAppStoreDSYMs
```
SWI only: See 'tvOSAppStoreDSYMs' lane.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
