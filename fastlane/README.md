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

### ios iOSnightlies

```sh
[bundle exec] fastlane ios iOSnightlies
```

Builds a new iOS nightly on App Store Connect and waits for build processing.

### ios nightlyTester

```sh
[bundle exec] fastlane ios nightlyTester
```

Adds a nightly TestFlight tester (email required)

### ios iOSbetasAppCenter

```sh
[bundle exec] fastlane ios iOSbetasAppCenter
```

Builds an iOS beta on App Center with the current build number. On the develop branch, attempts to tag the current version. On the develop or a feature branch, then bumps the build number and pushes.

### ios tvOSbetas

```sh
[bundle exec] fastlane ios tvOSbetas
```

Builds a tvOS beta on App Store Connect with the current build number and waits for build processing. On the develop branch, attempts to tag the current version. On the develop or a feature branch, then bumps the build number and pushes.

### ios iOSbetas

```sh
[bundle exec] fastlane ios iOSbetas
```

Builds an iOS beta on App Store Connect with the current build number and waits for build processing. On the develop branch, attempts to tag the current version. On the develop or a feature branch, then bumps the build number and pushes.

### ios betaTester

```sh
[bundle exec] fastlane ios betaTester
```

Adds a beta TestFlight tester (email required)

### ios iOSAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSAppStoreBuilds
```

Applies iOSUploadAppStoreBuilds and iOSDistributePrivateAppStoreBuilds (or iOSDistributePublicAppStoreBuilds). Optional `public_testflight_distribution` parameter.

### ios iOSUploadAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSUploadAppStoreBuilds
```

Uploads an iOS App Store build on App Store Connect with the current build number.

### ios iOSDistributePrivateAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSDistributePrivateAppStoreBuilds
```

Distributes to private groups an iOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`).

### ios iOSDistributePublicAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSDistributePublicAppStoreBuilds
```

Distributes to public groups an iOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`).

### ios tvOSAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSAppStoreBuilds
```

Applies tvOSUploadAppStoreBuilds and tvOSDistributePrivateAppStoreBuilds (or tvOSDistributePublicAppStoreBuilds). Optional `public_testflight_distribution` parameter.

### ios tvOSUploadAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSUploadAppStoreBuilds
```

Uploads a tvOS build on App Store Connect with the current build number.

### ios tvOSDistributePrivateAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSDistributePrivateAppStoreBuilds
```

Distributes to private groups a tvOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`).

### ios tvOSDistributePublicAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSDistributePublicAppStoreBuilds
```

Distributes to public groups a tvOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`).

### ios stopUnfinishedGithubDeployments

```sh
[bundle exec] fastlane ios stopUnfinishedGithubDeployments
```

Stop unfinished Github deployments for a lane on the current git branch. Recommended `lane` parameter.

### ios iOSPrepareAppStoreReleases

```sh
[bundle exec] fastlane ios iOSPrepareAppStoreReleases
```

Prepare AppStore iOS releases on App Store Connect with the current version and build numbers. No build uploads. Optional `tag_version` (`X.Y.Z-build_number`) or `submit_for_review` (boolean) parameters.

### ios tvOSPrepareAppStoreReleases

```sh
[bundle exec] fastlane ios tvOSPrepareAppStoreReleases
```

Prepare AppStore tvOS releases on App Store Connect with the current version and build numbers. No build uploads. Optional `tag_version` (`X.Y.Z-build_number`) or `submit_for_review` (boolean) parameters.

### ios appStoreAppStatus

```sh
[bundle exec] fastlane ios appStoreAppStatus
```

Get AppStore App status for iOS and tvOS. Optional `github_deployments` (boolean) parameter.

### ios appStoreTestFlightAppStatus

```sh
[bundle exec] fastlane ios appStoreTestFlightAppStatus
```

Get AppStore TestFlight App status for iOS and tvOS, lastest version

### ios publishReleaseNotes

```sh
[bundle exec] fastlane ios publishReleaseNotes
```

Publish release notes for iOS and tvOS on Github pages

### ios afterAppStoreValidationGitFlow

```sh
[bundle exec] fastlane ios afterAppStoreValidationGitFlow
```

After AppStore validation git flow: merges to master, tags released platforms, merges first tag to develop. Bumps marketing version and build number and pushes.

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

SRF: Makes iOS screenshots. No replacement made on App Store Connect.

### ios iOSswiScreenshots

```sh
[bundle exec] fastlane ios iOSswiScreenshots
```

SWI: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSrsiUploadAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrsiUploadAppStoreBuild
```

RSI only: See `iOSUploadAppStoreBuilds` lane.

### ios iOSrtrUploadAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtrUploadAppStoreBuild
```

RTR only: See `iOSUploadAppStoreBuilds` lane.

### ios iOSrtsUploadAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtsUploadAppStoreBuild
```

RTS only: See `iOSUploadAppStoreBuilds` lane.

### ios iOSsrfUploadAppStoreBuild

```sh
[bundle exec] fastlane ios iOSsrfUploadAppStoreBuild
```

SRF only: See `iOSUploadAppStoreBuilds` lane.

### ios iOSswiUploadAppStoreBuild

```sh
[bundle exec] fastlane ios iOSswiUploadAppStoreBuild
```

SWI only: See `iOSUploadAppStoreBuilds` lane.

### ios iOSrsiDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrsiDistributePrivateAppStoreBuild
```

RSI only: See `iOSDistributePrivateAppStoreBuilds` lane.

### ios iOSrtrDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtrDistributePrivateAppStoreBuild
```

RTR only: See `iOSDistributePrivateAppStoreBuilds` lane.

### ios iOSrtsDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtsDistributePrivateAppStoreBuild
```

RTS only: See `iOSDistributePrivateAppStoreBuilds` lane.

### ios iOSsrfDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios iOSsrfDistributePrivateAppStoreBuild
```

SRF only: See `iOSDistributePrivateAppStoreBuilds` lane.

### ios iOSswiDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios iOSswiDistributePrivateAppStoreBuild
```

SWI only: See `iOSDistributePrivateAppStoreBuilds` lane.

### ios iOSrsiDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrsiDistributePublicAppStoreBuild
```

RSI only: See `iOSDistributePublicAppStoreBuild` lane.

### ios iOSrtrDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtrDistributePublicAppStoreBuild
```

RTR only: See `iOSDistributePublicAppStoreBuild` lane.

### ios iOSrtsDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtsDistributePublicAppStoreBuild
```

RTS only: See `iOSDistributePublicAppStoreBuild` lane.

### ios iOSsrfDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios iOSsrfDistributePublicAppStoreBuild
```

SRF only: See `iOSDistributePublicAppStoreBuild` lane.

### ios iOSswiDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios iOSswiDistributePublicAppStoreBuild
```

SWI only: See `iOSDistributePublicAppStoreBuild` lane.

### ios iOSrsiPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios iOSrsiPrepareAppStoreRelease
```

RSI only: See `iOSPrepareAppStoreRelease` lane.

### ios iOSrtrPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios iOSrtrPrepareAppStoreRelease
```

RTR only: See `iOSPrepareAppStoreRelease` lane.

### ios iOSrtsPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios iOSrtsPrepareAppStoreRelease
```

RTS only: See `iOSPrepareAppStoreRelease` lane.

### ios iOSsrfPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios iOSsrfPrepareAppStoreRelease
```

SRF only: See `iOSPrepareAppStoreRelease` lane.

### ios iOSswiPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios iOSswiPrepareAppStoreRelease
```

SWI only: See `iOSPrepareAppStoreRelease` lane.

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

SRF: Makes tvOS screenshots. No replacement made on App Store Connect.

### ios tvOSswiScreenshots

```sh
[bundle exec] fastlane ios tvOSswiScreenshots
```

SWI: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSrsiUploadAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrsiUploadAppStoreBuild
```

RSI only: See `tvOSUploadAppStoreBuilds` lane.

### ios tvOSrtrUploadAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtrUploadAppStoreBuild
```

RTR only: See `tvOSUploadAppStoreBuilds` lane.

### ios tvOSrtsUploadAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtsUploadAppStoreBuild
```

RTS only: See `tvOSUploadAppStoreBuilds` lane.

### ios tvOSsrfUploadAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSsrfUploadAppStoreBuild
```

SRF only: See `tvOSUploadAppStoreBuilds` lane.

### ios tvOSswiUploadAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSswiUploadAppStoreBuild
```

SWI only: See `tvOSUploadAppStoreBuilds` lane.

### ios tvOSrsiDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrsiDistributePrivateAppStoreBuild
```

RSI only: See `tvOSDistributePrivateAppStoreBuilds` lane.

### ios tvOSrtrDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtrDistributePrivateAppStoreBuild
```

RTR only: See `tvOSDistributePrivateAppStoreBuilds` lane.

### ios tvOSrtsDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtsDistributePrivateAppStoreBuild
```

RTS only: See `tvOSDistributePrivateAppStoreBuilds` lane.

### ios tvOSsrfDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSsrfDistributePrivateAppStoreBuild
```

SRF only: See `tvOSDistributePrivateAppStoreBuilds` lane.

### ios tvOSswiDistributePrivateAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSswiDistributePrivateAppStoreBuild
```

SWI only: See `tvOSDistributePrivateAppStoreBuilds` lane.

### ios tvOSrsiDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrsiDistributePublicAppStoreBuild
```

RSI only: See `tvOSDistributePublicAppStoreBuilds` lane.

### ios tvOSrtrDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtrDistributePublicAppStoreBuild
```

RTR only: See `tvOSDistributePublicAppStoreBuilds` lane.

### ios tvOSrtsDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtsDistributePublicAppStoreBuild
```

RTS only: See `tvOSDistributePublicAppStoreBuilds` lane.

### ios tvOSsrfDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSsrfDistributePublicAppStoreBuild
```

SRF only: See `tvOSDistributePublicAppStoreBuilds` lane.

### ios tvOSswiDistributePublicAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSswiDistributePublicAppStoreBuild
```

SWI only: See `tvOSDistributePublicAppStoreBuilds` lane.

### ios tvOSrsiPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios tvOSrsiPrepareAppStoreRelease
```

RSI only: See `tvOSPrepareAppStoreRelease` lane.

### ios tvOSrtrPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios tvOSrtrPrepareAppStoreRelease
```

RTR only: See `tvOSPrepareAppStoreRelease` lane.

### ios tvOSrtsPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios tvOSrtsPrepareAppStoreRelease
```

RTS only: See `tvOSPrepareAppStoreRelease` lane.

### ios tvOSsrfPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios tvOSsrfPrepareAppStoreRelease
```

SRF only: See `tvOSPrepareAppStoreRelease` lane.

### ios tvOSswiPrepareAppStoreRelease

```sh
[bundle exec] fastlane ios tvOSswiPrepareAppStoreRelease
```

SWI only: See `tvOSPrepareAppStoreRelease` lane.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
