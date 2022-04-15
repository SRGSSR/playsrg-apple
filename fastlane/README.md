fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios iOSnightliesAppCenter

```sh
[bundle exec] fastlane ios iOSnightliesAppCenter
```

Builds a new iOS nightly on App Center.

### ios tvOSnightlies

```sh
[bundle exec] fastlane ios tvOSnightlies
```

Builds a new tvOS nightly on App Store Connect and waits for build processing.

### ios tvOSnightlyDSYMs

```sh
[bundle exec] fastlane ios tvOSnightlyDSYMs
```

Sends latest tvOS nightly dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios iOSnightlies

```sh
[bundle exec] fastlane ios iOSnightlies
```

Builds a new iOS nightly on App Store Connect and waits for build processing.

### ios iOSnightlyDSYMs

```sh
[bundle exec] fastlane ios iOSnightlyDSYMs
```

Sends latest iOS nightly dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios nightlyTester

```sh
[bundle exec] fastlane ios nightlyTester
```

Adds a nightly TestFlight tester (email required)

### ios iOSbetasAppCenter

```sh
[bundle exec] fastlane ios iOSbetasAppCenter
```

Builds an iOS beta on App Center with the current build number. On the develop branch attempts to tag the current version, then bumps the build number and pushes.

### ios tvOSbetas

```sh
[bundle exec] fastlane ios tvOSbetas
```

Builds a tvOS beta on App Store Connect with the current build number and waits for build processing. On the develop branch attempts to tag the current version, then bumps the build number and pushes.

### ios tvOSbetaDSYMs

```sh
[bundle exec] fastlane ios tvOSbetaDSYMs
```

Sends latest tvOS beta dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios iOSbetas

```sh
[bundle exec] fastlane ios iOSbetas
```

Builds an iOS beta on App Store Connect with the current build number and waits for build processing. On the develop branch attempts to tag the current version, then bumps the build number and pushes.

### ios iOSbetaDSYMs

```sh
[bundle exec] fastlane ios iOSbetaDSYMs
```

Sends latest iOS beta dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios betaTester

```sh
[bundle exec] fastlane ios betaTester
```

Adds a beta TestFlight tester (email required)

### ios iOSAppStoreBetas

```sh
[bundle exec] fastlane ios iOSAppStoreBetas
```

Applies iOSAppStoreUploadBetas, iOSAppStoreDistributePrivateBetas and iOSAppStoreDSYMs.

### ios iOSAppStoreUploadBetas

```sh
[bundle exec] fastlane ios iOSAppStoreUploadBetas
```

Uploads an iOS App Store beta on App Store Connect with the current build number.

### ios iOSAppStoreDistributePrivateBetas

```sh
[bundle exec] fastlane ios iOSAppStoreDistributePrivateBetas
```

Distributes to private groups an iOS App Store beta on App Store Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).

### ios iOSAppStoreDistributePublicBetas

```sh
[bundle exec] fastlane ios iOSAppStoreDistributePublicBetas
```

Distributes to public groups an iOS App Store beta on App Store Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).

### ios iOSAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSAppStoreDSYMs
```

Sends latest iOS App Store dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios tvOSAppStoreBetas

```sh
[bundle exec] fastlane ios tvOSAppStoreBetas
```

Applies tvOSAppStoreUploadBetas, tvOSAppStoreDistributePrivateBetas and tvOSAppStoreDSYMs.

### ios tvOSAppStoreUploadBetas

```sh
[bundle exec] fastlane ios tvOSAppStoreUploadBetas
```

Uploads a tvOS build on App Store Connect with the current build number.

### ios tvOSAppStoreDistributePrivateBetas

```sh
[bundle exec] fastlane ios tvOSAppStoreDistributePrivateBetas
```

Distributes to private groups a tvOS App Store beta on App Store Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).

### ios tvOSAppStoreDistributePublicBetas

```sh
[bundle exec] fastlane ios tvOSAppStoreDistributePublicBetas
```

Distributes to public groups a tvOS App Store beta on App Store Connect with the current build number. Optional 'tag_version' parameter (X.Y.Z-build_number).

### ios tvOSAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSAppStoreDSYMs
```

Sends latest tvOS dSYMs to App Center. Optional 'build_number', 'version' or 'min_version' parameters.

### ios iOSrsiScreenshots

```sh
[bundle exec] fastlane ios iOSrsiScreenshots
```

RSI: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSrtrScreenshots

```sh
[bundle exec] fastlane ios iOSrtrScreenshots
```

RTR: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSrtsScreenshots

```sh
[bundle exec] fastlane ios iOSrtsScreenshots
```

RTS: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSsrfScreenshots

```sh
[bundle exec] fastlane ios iOSsrfScreenshots
```

SRF: Makes iOS screenshots. !!! No replacement made on App Store Connect !!!

### ios iOSswiScreenshots

```sh
[bundle exec] fastlane ios iOSswiScreenshots
```

SWI: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSrsiAppStoreUploadBeta

```sh
[bundle exec] fastlane ios iOSrsiAppStoreUploadBeta
```

RSI only: See 'iOSAppStoreUploadBetas' lane.

### ios iOSrtrAppStoreUploadBeta

```sh
[bundle exec] fastlane ios iOSrtrAppStoreUploadBeta
```

RTR only: See 'iOSAppStoreUploadBetas' lane.

### ios iOSrtsAppStoreUploadBeta

```sh
[bundle exec] fastlane ios iOSrtsAppStoreUploadBeta
```

RTS only: See 'iOSAppStoreUploadBetas' lane.

### ios iOSsrfAppStoreUploadBeta

```sh
[bundle exec] fastlane ios iOSsrfAppStoreUploadBeta
```

SRF only: See 'iOSAppStoreUploadBetas' lane.

### ios iOSswiAppStoreUploadBeta

```sh
[bundle exec] fastlane ios iOSswiAppStoreUploadBeta
```

SWI only: See 'iOSAppStoreUploadBetas' lane.

### ios iOSrsiAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios iOSrsiAppStoreDistributePrivateBeta
```

RSI only: See 'iOSAppStoreDistributePrivateBetas' lane.

### ios iOSrtrAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios iOSrtrAppStoreDistributePrivateBeta
```

RTR only: See 'iOSAppStoreDistributePrivateBetas' lane.

### ios iOSrtsAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios iOSrtsAppStoreDistributePrivateBeta
```

RTS only: See 'iOSAppStoreDistributePrivateBetas' lane.

### ios iOSsrfAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios iOSsrfAppStoreDistributePrivateBeta
```

SRF only: See 'iOSAppStoreDistributePrivateBetas' lane.

### ios iOSswiAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios iOSswiAppStoreDistributePrivateBeta
```

SWI only: See 'iOSAppStoreDistributePrivateBetas' lane.

### ios iOSrsiAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios iOSrsiAppStoreDistributePublicBeta
```

RSI only: See 'iOSAppStoreDistributePublicBeta' lane.

### ios iOSrtrAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios iOSrtrAppStoreDistributePublicBeta
```

RTR only: See 'iOSAppStoreDistributePublicBeta' lane.

### ios iOSrtsAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios iOSrtsAppStoreDistributePublicBeta
```

RTS only: See 'iOSAppStoreDistributePublicBeta' lane.

### ios iOSsrfAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios iOSsrfAppStoreDistributePublicBeta
```

SRF only: See 'iOSAppStoreDistributePublicBeta' lane.

### ios iOSswiAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios iOSswiAppStoreDistributePublicBeta
```

SWI only: See 'iOSAppStoreDistributePublicBeta' lane.

### ios iOSrsiAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSrsiAppStoreDSYMs
```

RSI only: See 'iOSAppStoreDSYMs' lane.

### ios iOSrtrAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSrtrAppStoreDSYMs
```

RTR only: See 'iOSAppStoreDSYMs' lane.

### ios iOSrtsAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSrtsAppStoreDSYMs
```

RTS only: See 'iOSAppStoreDSYMs' lane.

### ios iOSsrfAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSsrfAppStoreDSYMs
```

SFR only: See 'iOSAppStoreDSYMs' lane.

### ios iOSswiAppStoreDSYMs

```sh
[bundle exec] fastlane ios iOSswiAppStoreDSYMs
```

SWI only: See 'iOSAppStoreDSYMs' lane.

### ios tvOSrsiScreenshots

```sh
[bundle exec] fastlane ios tvOSrsiScreenshots
```

RSI: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSrtrScreenshots

```sh
[bundle exec] fastlane ios tvOSrtrScreenshots
```

RTR: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSrtsScreenshots

```sh
[bundle exec] fastlane ios tvOSrtsScreenshots
```

RTS: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSsrfScreenshots

```sh
[bundle exec] fastlane ios tvOSsrfScreenshots
```

SRF: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSswiScreenshots

```sh
[bundle exec] fastlane ios tvOSswiScreenshots
```

SWI: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSrsiAppStoreUploadBeta

```sh
[bundle exec] fastlane ios tvOSrsiAppStoreUploadBeta
```

RSI only: See 'tvOSAppStoreUploadBetas' lane.

### ios tvOSrtrAppStoreUploadBeta

```sh
[bundle exec] fastlane ios tvOSrtrAppStoreUploadBeta
```

RTR only: See 'tvOSAppStoreUploadBetas' lane.

### ios tvOSrtsAppStoreUploadBeta

```sh
[bundle exec] fastlane ios tvOSrtsAppStoreUploadBeta
```

RTS only: See 'tvOSAppStoreUploadBetas' lane.

### ios tvOSsrfAppStoreUploadBeta

```sh
[bundle exec] fastlane ios tvOSsrfAppStoreUploadBeta
```

SRF only: See 'tvOSAppStoreUploadBetas' lane.

### ios tvOSswiAppStoreUploadBeta

```sh
[bundle exec] fastlane ios tvOSswiAppStoreUploadBeta
```

SWI only: See 'tvOSAppStoreUploadBetas' lane.

### ios tvOSrsiAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios tvOSrsiAppStoreDistributePrivateBeta
```

RSI only: See 'tvOSAppStoreDistributePrivateBetas' lane.

### ios tvOSrtrAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios tvOSrtrAppStoreDistributePrivateBeta
```

RTR only: See 'tvOSAppStoreDistributePrivateBetas' lane.

### ios tvOSrtsAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios tvOSrtsAppStoreDistributePrivateBeta
```

RTS only: See 'tvOSAppStoreDistributePrivateBetas' lane.

### ios tvOSsrfAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios tvOSsrfAppStoreDistributePrivateBeta
```

SRF only: See 'tvOSAppStoreDistributePrivateBetas' lane.

### ios tvOSswiAppStoreDistributePrivateBeta

```sh
[bundle exec] fastlane ios tvOSswiAppStoreDistributePrivateBeta
```

SWI only: See 'tvOSAppStoreDistributePrivateBetas' lane.

### ios tvOSrsiAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios tvOSrsiAppStoreDistributePublicBeta
```

RSI only: See 'tvOSAppStoreDistributePublicBetas' lane.

### ios tvOSrtrAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios tvOSrtrAppStoreDistributePublicBeta
```

RTR only: See 'tvOSAppStoreDistributePublicBetas' lane.

### ios tvOSrtsAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios tvOSrtsAppStoreDistributePublicBeta
```

RTS only: See 'tvOSAppStoreDistributePublicBetas' lane.

### ios tvOSsrfAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios tvOSsrfAppStoreDistributePublicBeta
```

SRF only: See 'tvOSAppStoreDistributePublicBetas' lane.

### ios tvOSswiAppStoreDistributePublicBeta

```sh
[bundle exec] fastlane ios tvOSswiAppStoreDistributePublicBeta
```

SWI only: See 'tvOSAppStoreDistributePublicBetas' lane.

### ios tvOSrsiAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSrsiAppStoreDSYMs
```

RSI only: See 'tvOSAppStoreDSYMs' lane.

### ios tvOSrtrAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSrtrAppStoreDSYMs
```

RTR only: See 'tvOSAppStoreDSYMs' lane.

### ios tvOSrtsAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSrtsAppStoreDSYMs
```

RTS only: See 'tvOSAppStoreDSYMs' lane.

### ios tvOSsrfAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSsrfAppStoreDSYMs
```

SFR only: See 'tvOSAppStoreDSYMs' lane.

### ios tvOSswiAppStoreDSYMs

```sh
[bundle exec] fastlane ios tvOSswiAppStoreDSYMs
```

SWI only: See 'tvOSAppStoreDSYMs' lane.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
