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

### ios tvOSbetas

```sh
[bundle exec] fastlane ios tvOSbetas
```

Builds a tvOS beta on App Store Connect with the current build number and waits for build processing. On the main branch, attempts to tag the current version. On the main or a branch, then bumps the build number and pushes. On a branch, try to report the new build number to main branch.

### ios iOSbetas

```sh
[bundle exec] fastlane ios iOSbetas
```

Builds an iOS beta on App Store Connect with the current build number and waits for build processing. On the main branch, attempts to tag the current version. On the main or a branch, then bumps the build number and pushes. On a branch, try to report the new build number to main branch.

### ios betaTester

```sh
[bundle exec] fastlane ios betaTester
```

Adds a beta TestFlight tester (email required)

### ios iOSAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSAppStoreBuilds
```

Applies iOSUploadAppStoreBuilds and iOSDistributeAppStoreBuilds. Optional `public_beta_distribution` parameter, default value is `true`.

### ios iOSUploadAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSUploadAppStoreBuilds
```

Uploads an iOS App Store build on App Store Connect with the current build number.

### ios iOSDistributeAppStoreBuilds

```sh
[bundle exec] fastlane ios iOSDistributeAppStoreBuilds
```

Distributes to TestFlight groups an iOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`). Optional `public_beta_distribution` parameter, default value is `true`.

### ios tvOSAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSAppStoreBuilds
```

Applies tvOSUploadAppStoreBuilds and tvOSDistributeAppStoreBuilds. Optional `public_beta_distribution` parameter, default value is `true`.

### ios tvOSUploadAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSUploadAppStoreBuilds
```

Uploads a tvOS build on App Store Connect with the current build number.

### ios tvOSDistributeAppStoreBuilds

```sh
[bundle exec] fastlane ios tvOSDistributeAppStoreBuilds
```

Distributes to TestFlight groups a tvOS App Store build on App Store Connect with the current version and build numbers. Optional `tag_version` parameter (`X.Y.Z-build_number`). Optional `public_beta_distribution` parameter, default value is `true`.

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

Get AppStore App status for iOS and tvOS. Optional `github_deployments` (boolean) and `publish_release_notes` (boolean) parameters.

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

### ios afterAppStoreRelease

```sh
[bundle exec] fastlane ios afterAppStoreRelease
```

After an AppStore release: Bumps marketing version and pushes if one AppStore live version is same as the current marketing version.

### ios iOSrsiScreenshots

```sh
[bundle exec] fastlane ios iOSrsiScreenshots
```

RSI: Makes iOS screenshots and replaces current ones on App Store Connect.

### ios iOSrtrScreenshots

```sh
[bundle exec] fastlane ios iOSrtrScreenshots
```

RTR: Makes iOS screenshots. No replacement made on App Store Connect.

### ios iOSrtsScreenshots

```sh
[bundle exec] fastlane ios iOSrtsScreenshots
```

RTS: Makes iOS screenshots. No replacement made on App Store Connect.

### ios iOSsrfScreenshots

```sh
[bundle exec] fastlane ios iOSsrfScreenshots
```

SRF: Makes iOS screenshots. No replacement made on App Store Connect.

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

### ios iOSrsiDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrsiDistributeAppStoreBuild
```

RSI only: See `iOSDistributeAppStoreBuilds` lane.

### ios iOSrtrDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtrDistributeAppStoreBuild
```

RTR only: See `iOSDistributeAppStoreBuilds` lane.

### ios iOSrtsDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios iOSrtsDistributeAppStoreBuild
```

RTS only: See `iOSDistributeAppStoreBuilds` lane.

### ios iOSsrfDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios iOSsrfDistributeAppStoreBuild
```

SRF only: See `iOSDistributeAppStoreBuilds` lane.

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

### ios tvOSrsiScreenshots

```sh
[bundle exec] fastlane ios tvOSrsiScreenshots
```

RSI: Makes tvOS screenshots and replaces current ones on App Store Connect.

### ios tvOSrtrScreenshots

```sh
[bundle exec] fastlane ios tvOSrtrScreenshots
```

RTR: Makes tvOS screenshots. No replacement made on App Store Connect.

### ios tvOSrtsScreenshots

```sh
[bundle exec] fastlane ios tvOSrtsScreenshots
```

RTS: Makes tvOS screenshots. No replacement made on App Store Connect.

### ios tvOSsrfScreenshots

```sh
[bundle exec] fastlane ios tvOSsrfScreenshots
```

SRF: Makes tvOS screenshots. No replacement made on App Store Connect.

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

### ios tvOSrsiDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrsiDistributeAppStoreBuild
```

RSI only: See `tvOSDistributeAppStoreBuilds` lane.

### ios tvOSrtrDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtrDistributeAppStoreBuild
```

RTR only: See `tvOSDistributeAppStoreBuilds` lane.

### ios tvOSrtsDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSrtsDistributeAppStoreBuild
```

RTS only: See `tvOSDistributeAppStoreBuilds` lane.

### ios tvOSsrfDistributeAppStoreBuild

```sh
[bundle exec] fastlane ios tvOSsrfDistributeAppStoreBuild
```

SRF only: See `tvOSDistributeAppStoreBuilds` lane.

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

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
