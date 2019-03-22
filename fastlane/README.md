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
For each BUs, build a new nightly on HockeyApp, with a new build number, greater than the old nightly build number
### ios betas
```
fastlane ios betas
```
For each BUs, build a new beta on HockeyApp with the current build number. If we're not in a release or hotfix process (master, release/* or hotfix/*), tag the current version on the repository and bump the build number
### ios swiTestFlight
```
fastlane ios swiTestFlight
```
SWI: Upload a new TestFlight build with the current build number and send the dSYM on HockeyApp.
### ios srfTestFlight
```
fastlane ios srfTestFlight
```
SRF: Upload a new TestFlight build with the current build number and send the dSYM on HockeyApp.
### ios rtsTestFlight
```
fastlane ios rtsTestFlight
```
RTS: Upload a new TestFlight build with the current build number and send the dSYM on HockeyApp.
### ios rsiTestFlight
```
fastlane ios rsiTestFlight
```
RSI: Upload a new TestFlight build with the current build number and send the dSYM on HockeyApp.
### ios rtrTestFlight
```
fastlane ios rtrTestFlight
```
RTR: Upload a new TestFlight build with the current build number and send the dSYM on HockeyApp.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
