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
### ios iOSAppStoreDistributePrivateBetas
```
fastlane ios iOSAppStoreDistributePrivateBetas
```
Distribute the iOS AppStore build on AppStore Connect with the current build number to private group.
### ios iOSAppStoreDistributePublicBetas
```
fastlane ios iOSAppStoreDistributePublicBetas
```
Distribute the iOS AppStore build on AppStore Connect with the current build number to public group.
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
### ios tvOSAppStoreDistributePrivateBetas
```
fastlane ios tvOSAppStoreDistributePrivateBetas
```
Distribute the tvOS AppStore build on AppStore Connect with the current build number to private group.
### ios tvOSAppStoreDistributePublicBetas
```
fastlane ios tvOSAppStoreDistributePublicBetas
```
Distribute the tvOS AppStore build on AppStore Connect with the current build number to public group.
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
SRF: Makes iOS screenshots. !!! No replacements on AppStoreConnect done !!!
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
SWI only: See 'iOSAppStoreUploads' lane.
### ios iOSsrfAppStoreUpload
```
fastlane ios iOSsrfAppStoreUpload
```
SRF only: See 'iOSAppStoreUploads' lane.
### ios iOSrtsAppStoreUpload
```
fastlane ios iOSrtsAppStoreUpload
```
RTS only: See 'iOSAppStoreUploads' lane.
### ios iOSrsiAppStoreUpload
```
fastlane ios iOSrsiAppStoreUpload
```
RSI only: See 'iOSAppStoreUploads' lane.
### ios iOSrtrAppStoreUpload
```
fastlane ios iOSrtrAppStoreUpload
```
RTR only: See 'iOSAppStoreUploads' lane.
### ios iOSswiAppStoreDistributePrivateBeta
```
fastlane ios iOSswiAppStoreDistributePrivateBeta
```
SWI only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSsrfAppStoreDistributePrivateBeta
```
fastlane ios iOSsrfAppStoreDistributePrivateBeta
```
SRF only: See 'iOSAppStoreDistributePrivateBetas' lane.
### ios iOSrtsAppStoreDistributePrivateBeta
```
fastlane ios iOSrtsAppStoreDistributePrivateBeta
```
RTS only: See 'iOSAppStoreDistributePrivateBetas' lane.
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
### ios iOSswiAppStoreDistributePublicBeta
```
fastlane ios iOSswiAppStoreDistributePublicBeta
```
SWI only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSsrfAppStoreDistributePublicBeta
```
fastlane ios iOSsrfAppStoreDistributePublicBeta
```
SRF only: See 'iOSAppStoreDistributePublicBeta' lane.
### ios iOSrtsAppStoreDistributePublicBeta
```
fastlane ios iOSrtsAppStoreDistributePublicBeta
```
RTS only: See 'iOSAppStoreDistributePublicBeta' lane.
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
### ios iOSswiDSYMs
```
fastlane ios iOSswiDSYMs
```
SWI only: See 'iOSDSYMs' lane.
### ios iOSsrfDSYMs
```
fastlane ios iOSsrfDSYMs
```
SFR only: See 'iOSDSYMs' lane.
### ios iOSrtsDSYMs
```
fastlane ios iOSrtsDSYMs
```
RTS only: See 'iOSDSYMs' lane.
### ios iOSrsiDSYMs
```
fastlane ios iOSrsiDSYMs
```
RSI only: See 'iOSDSYMs' lane.
### ios iOSrtrDSYMs
```
fastlane ios iOSrtrDSYMs
```
RTR only: See 'iOSDSYMs' lane.
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
SWI only: See 'tvOSAppStoreUploads' lane.
### ios tvOSsrfAppStoreUpload
```
fastlane ios tvOSsrfAppStoreUpload
```
SRF only: See 'tvOSAppStoreUploads' lane.
### ios tvOSrtsAppStoreUpload
```
fastlane ios tvOSrtsAppStoreUpload
```
RTS only: See 'tvOSAppStoreUploads' lane.
### ios tvOSrsiAppStoreUpload
```
fastlane ios tvOSrsiAppStoreUpload
```
RSI only: See 'tvOSAppStoreUploads' lane.
### ios tvOSrtrAppStoreUpload
```
fastlane ios tvOSrtrAppStoreUpload
```
RTR only: See 'tvOSAppStoreUploads' lane.
### ios tvOSswiAppStoreDistributePrivateBeta
```
fastlane ios tvOSswiAppStoreDistributePrivateBeta
```
SWI only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSsrfAppStoreDistributePrivateBeta
```
fastlane ios tvOSsrfAppStoreDistributePrivateBeta
```
SRF only: See 'tvOSAppStoreDistributePrivateBetas' lane.
### ios tvOSrtsAppStoreDistributePrivateBeta
```
fastlane ios tvOSrtsAppStoreDistributePrivateBeta
```
RTS only: See 'tvOSAppStoreDistributePrivateBetas' lane.
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
### ios tvOSswiAppStoreDistributePublicBeta
```
fastlane ios tvOSswiAppStoreDistributePublicBeta
```
SWI only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSsrfAppStoreDistributePublicBeta
```
fastlane ios tvOSsrfAppStoreDistributePublicBeta
```
SRF only: See 'tvOSAppStoreDistributePublicBetas' lane.
### ios tvOSrtsAppStoreDistributePublicBeta
```
fastlane ios tvOSrtsAppStoreDistributePublicBeta
```
RTS only: See 'tvOSAppStoreDistributePublicBetas' lane.
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
### ios tvOSswiDSYMs
```
fastlane ios tvOSswiDSYMs
```
SWI only: See 'tvOSDSYMs' lane.
### ios tvOSsrfDSYMs
```
fastlane ios tvOSsrfDSYMs
```
SFR only: See 'tvOSDSYMs' lane.
### ios tvOSrtsDSYMs
```
fastlane ios tvOSrtsDSYMs
```
RTS only: See 'tvOSDSYMs' lane.
### ios tvOSrsiDSYMs
```
fastlane ios tvOSrsiDSYMs
```
RSI only: See 'tvOSDSYMs' lane.
### ios tvOSrtrDSYMs
```
fastlane ios tvOSrtrDSYMs
```
RTR only: See 'tvOSDSYMs' lane.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
