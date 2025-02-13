# Workflows<!-- omit from toc -->

The project implements some workflows. It a mix of:

- Fastlane scripts (mostly running on an [on premise TeamCity instance](https://playcity.eu.ngrok.io/project/playsrgios) but can be run locally as well).
- Bash scripts (locally with `make` commands).
- Github actions (running on [github.com](https://github.com/SRGSSR/playsrg-apple)).

### Table of Contents
- [Start a feature or a bug fix](#start-a-feature-or-a-bug-fix)
    - [Start from an internal Jira ticket](#start-from-an-internal-jira-ticket)
    - [Start from a public Github issue](#start-from-a-public-github-issue)
- [Build and distribute Private Nightlies](#build-and-distribute-private-nightlies)
- [Submit to review a feature or a bug fix](#submit-to-review-a-feature-or-a-bug-fix)
- [Build and distribute Private Betas](#build-and-distribute-private-betas)
- [Build and distribute Public Betas and AppStore Builds](#build-and-distribute-public-betas-and-appstore-builds)
- [Prepare an App Store release](#prepare-an-app-store-release)
- [Update the App Store screenshots](#update-the-app-store-screenshots)
- [Submit an App Store release for review](#submit-an-app-store-release-for-review)
- [Follow App Store release status](#follow-app-store-release-status)
- [Release notes on Github pages](#release-notes-on-github-pages)
- [Bump platform version after a release](#bump-platform-version-after-a-release)

# Start a feature or a bug fix

🙏 Please first run one time on the Mac, `make git-hook-install`, so that the `pre-commit` linter and Jira `commit-msg` are installed.

### Start from an internal Jira ticket

1. Create a branch from `main` with this naming convention: `JIRA-1235-feature-b`. Start with the Jira ticket id.
2. Checkout the new branch.
3. Commit your changes with the Jira ticket id in the commit message. `commit-msg` git hook will do it automatically.

ℹ️ The Jira website could help and proposes to create the branch from the ticket page.

![Jira branch creation](WORKFLOWS-images/jira-branch-creation.jpg)

```mermaid
---
title: New branch from a Jira ticket
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
	commit id: "JIRA-1234 Feature A (#456)"
	commit id: "JIRA-1235 Feature B (#457)"
    branch JIRA-1236-feature-c
    checkout JIRA-1236-feature-c
    commit id: "JIRA-1236 Commit 1" type: HIGHLIGHT
	commit id: "JIRA-1236 Commit 2" type: HIGHLIGHT
```

### Start from a public Github issue

1. Create a branch from `main` with this naming convention: `1235-feature-b`. Start with the Github issue id.
2. Checkout the new branch.
3. Commit your changes with the Github issue id in the commit message if possible.

ℹ️ The Github website could also help and proposes to create the branch from the issue page.

![Github branch creation](WORKFLOWS-images/github-branch-creation.jpg)

```mermaid
---
title: New branch from a Github issue
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
	commit id: "JIRA-1234 Feature A (#456)"
	commit id: "JIRA-1235 Feature B (#457)"
    branch 1236-feature-c
    checkout 1236-feature-c
    commit id: "#1236 Commit 1" type: HIGHLIGHT
	commit id: "#1236 Commit 2" type: HIGHLIGHT
```

# Build and distribute Private Nightlies

During the development, non-public builds can be done for internal testers so that they can validate the implementation.

1. On PlayCity CI select the project:
   - **[Play SRG iOS Nightlies 🌱🌙](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_NightliesIOS)**: `fastlane ios iOSnightlies`
   - **[Play SRG tvOS Nightlies 🌱🌙](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_NightliesTvOS)**: `fastlane ios tvOSnightlies`
2. Select the branch.
3. Run the project. Private Nighties builds have:
   - the current version (`X.Y.Z`) on the repository.
   - a build number (`N`) incremented from the last one found on App Store Connect. Build number is not versioned on git.
   - a displayed name containing:
       - "🌙" if built from the `main` branch.
       - "🌱" if built from another branch.
       - the branch name if it's not the `main` branch.
     - then an upload to App Store Connect and are distributed to the SRG Testers TestFlight group.
     - TestFlight release notes from commit messages. No additional commits needed.

ℹ️ If running the project on a same commit and branch, new builds are done and distributed.

# Submit to review a feature or a bug fix

When the feature or the bug fix branch is ready to be tested and reviewed:

1. A [pull request](https://github.com/SRGSSR/playsrg-apple/pulls) is opened from the branch to be merged to the `main` branch.
2. Set the Jira ticket id in the PR title and a comprehensive title. Example: `JIRA-1236 Feature C`. The Github PR id will be added during the merge, later.
3. Add [one label](https://github.com/SRGSSR/playsrg-apple/labels) to the PR.
	- They are used for automatically generated Github release notes, later with tag releases.
	- A [Github action](https://github.com/SRGSSR/playsrg-apple/actions/workflows/check-pr-labels.yml) is checking that one allowed label is added.
4. Add reviewers to the PR. At least one team member has to review the PR. 
   - Conversations, code propositions, architecture or UI/UX remarks could be added and has to be solved.
5. ✅ When the feature or the bug fix is validated and the PR is reviewed, add the PR to the Github queue.
   - A squash commit is done, added onto the `main` branch after passed tests.
   - The commit message is the PR title and the PR Github id.
   - The PR branch is deleted.

```mermaid
---
title: Squash and merge PR branch
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
	commit id: "JIRA-1234 Feature A (#456)"
	commit id: "JIRA-1235 Feature B (#457)"
    branch JIRA-1236-feature-c
    checkout JIRA-1236-feature-c
    commit id: "JIRA-1236 Commit 1"
	commit id: "JIRA-1236 Commit 2"
	checkout main
	commit id: "JIRA-1236 Feature B (#458)" type: HIGHLIGHT
	checkout JIRA-1236-feature-c
	commit id: "JIRA-1236-feature-c branch deleted" type: REVERSE
```

# Build and distribute Private Betas

Before a release and sometime, during the development, non-public **stable** builds can be done for internal testers so that they can validate the feature or the fix.

ℹ️ The Private Betas workflow can be scheduled because of dependency with the Public Betas workflow on PlayCity CI. If it's the plan to build both private and public betas, please refer to the next section: [Build and distribute Public Betas and AppStore builds](#build-and-distribute-public-betas-and-appStore-builds).

1. Commit the release notes for the Betas on the future built branch. Those files are:
    - `WhatsNew-iOS-beta.json` for iOS platform.
    - `WhatsNew-tvOS-beta.json` for tvOS platform.
    - Can be done in one unique commit with "Update what's new" message.
2. Push the commit to the repository.
3. On PlayCity CI select the project:
   - **[Play SRG iOS Betas 🪴🎯](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_BetasIOS)**: `fastlane ios iOSbetas`
   - **[Play SRG tvOS Betas 🪴🎯](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_BetasTvOS)**: `fastlane ios tvOSbetas`
4. Select the branch (most of the time, it's the `main` branch).
5. Run the project. Private Betas builds have:
   - the current version (`X.Y.Z`) on the repository.
   - the current build number (`N`) on the repository.
   - a displayed name containing:
       - "🎯" if built from the `main` branch.
       - "🪴" if built from another branch.
       - the branch name if it's not the `main` branch.
     - then an upload to App Store Connect and are distributed to the SRG Testers TestFlight group.
     - TestFlight release notes from the `WhatsNew-iOS-beta.json` and `WhatsNew-tvOS-beta.json` files.
     - Then, the current commit is tagged with `[ios|tvos]/X.Y.Z-N` if the build is on the `main` branch.
     - Then, the build number (`N`) is incremented and commited on the current branch with message "Bump build number to `N`+1".
     - Then, if the build is on another branch, no tags. The latest "Update what's new" and "Bump build number to `N`+1" commits are cherry-picked to the `main` branch.

ℹ️ If running the project on a same commit and branch, no new builds are done, only the distribution is done again.

```mermaid
---
title: Beta from the main branch
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
    commit id: "JIRA-1234 Feature A (#456)"
    commit id: "JIRA-1235 Feature B (#457)"
	commit id: "JIRA-1236 Feature C (#458)"
    commit tag: "tag [ios|tvOS]/X.Y.Z-N" id: "Update what's new"
    commit id: "Bump build number to N+1" type: HIGHLIGHT
```

```mermaid
---
title: Beta from another branch
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
	commit id: "JIRA-1234 Feature A (#456)"
	commit id: "JIRA-1235 Feature B (#457)"
	branch JIRA-1236-feature-c
	checkout JIRA-1236-feature-c
	commit id: "JIRA-1236 Commit 1"
	commit id: "JIRA-1236 Commit 2"
    commit id: "JIRA-1236 Update what's new"
    commit id: "Bump build number to N+1" type: HIGHLIGHT
	checkout main
	cherry-pick id: "JIRA-1236 Update what's new"
	cherry-pick id: "Bump build number to N+1"
```

# Build and distribute Public Betas and AppStore Builds

For a release and sometime, during the development, external **stable** builds can be done for early adopters, our best testers.

ℹ️ The Public Beta builds are named "AppStore Builds" as they are the same builds distributed on the App Store after an Apple review. Almost, they are based on the same branch and commit as the Private Beta builds and share the same version (`X.Y.Z`) and build number (`N`).

- ⚠️ An AppStore Builds must be run a tagged commit, otherwise, the Private Betas workflow will be scheduled before on PlayCity CI.

1. Verify that the release notes for the Betas are commited on the branch. Those files are:
    - `WhatsNew-iOS-beta.json` for iOS platform.
    - `WhatsNew-tvOS-beta.json` for tvOS platform.
2. On PlayCity CI select the project:
    - **[Play SRG iOS AppStore builds 🌳](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_TestFlightIOS)**: `fastlane ios iOSAppStoreBuilds public_beta_distribution:true`
    - **[Play SRG tvOS AppStore builds 🌳](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_TestFlightTvOS)**: `fastlane ios tvOSAppStoreBuilds public_beta_distribution:true`
3. Select the branch (most of the time, it's the `main` branch).
4. Select the commit with the tag (or future tag).
5. (optional) Unselect the `public_beta_distribution` parameter only if you want to keep the build not distributed to the public Beta Testers TestFlight group. It must be rerun with the parameter to distribute it later. Never forget early adopters.
6. Run the project. AppStore Builds have:
   - the current version (`X.Y.Z`) on the repository.
   - the current build number (`N`) on the repository.
   - a displayed name containing:
       - No emoji if built from the `main` branch.
       - "🌳" if built from another branch.
       - the branch name if it's not the `main` branch.
   - then an upload to App Store Connect and are distributed to the SRG Testers TestFlight group.
   - also a distribution to the Public Beta Testers TestFlight group if no `public_beta_distribution` parameter set or set it to `true`.
   - TestFlight release notes from the `WhatsNew-iOS-beta.json` and `WhatsNew-tvOS-beta.json` files.
7. We can follow the Apple TestFlight review status locally with `make appstore-testflight-status`.

ℹ️ If running the project on a same commit and branch, no new builds are done, only the distribution is done again.

# Prepare an App Store release

🙋**It's recommended to have the markdown [release checklist](RELEASE_CHECKLIST.md) in a shared Jira ticket or github issue to follow steps.** 

ℹ️ The App Store release needs a public and translated what's new App Store release notes.

On [crowdin.com PlaySRG project](https://crowdin.com/project/play-srg/sources/files), `What_s new iOS.csv` and `What_s new tvOS.csv` files are used to translate the release notes from English to Italian, Romansh, French and German.
	
1. Download the csv source files from [crowdin.com](https://crowdin.com/project/play-srg/sources/files).
2. Add the new version entry to the csv files, with the English text.
3. Upload the updated csv files to crowdin.com.
4. Ask the translators ([play-srg-translators@rts.ch](mailto:play-srg-translators@rts.ch)) to translate the new entries.
5. On PlayCity CI select the project:
    - **[Play SRG iOS AppStore releases](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgIOSAppStoreReleases)**: `fastlane ios iOSPrepareAppStoreReleases`
    - **[Play SRG tvOS AppStore releases](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgTvOSAppStoreReleases)**: `fastlane ios tvOSPrepareAppStoreReleases`
6. "Run" the project to open the dialog view.
7. In the *Parameters* tab, set the `tag_version` parameter (`X.Y.Z-N`) to use, if the version on `main` branch is not the expected one (**should not be the case**).
8. "Run build" from the dialog view. The script:
   - Creates a new App Store release on App Store Connect with the current version if not already existing.
   - Sets the translated what's new for this version.
   - Updates the what's new App Store release notes with the translated release notes from crowdin.com.
   - Does some basic metadata checks with [Fastlane precheck](https://docs.fastlane.tools/actions/precheck/).
   - No submission to Apple review is done for now.
9. We can follow Apple release status and what's new release notes locally with `make appstore-status`.

ℹ️ The project can be rerun to update the translated App Store release notes if needed.

```mermaid
---
title: Prepare an App Store release
---
sequenceDiagram
    Fastlane->>Crowdin: Ask what's new translated csv files
    activate Fastlane
	activate Crowdin
	Crowdin-->>Fastlane: Get what's new translated csv files
	deactivate Crowdin
	participant ASC as App Store Connect
	Fastlane->>ASC: Create a new App Store release for the current version if not existing
	activate ASC
	ASC-->>Fastlane: Get App Store Connect version
	Fastlane->>ASC: Set translated what's new for this version
	deactivate ASC
	deactivate Fastlane
```

# Update the App Store screenshots

Optional, update the App Store screenshots with the latest version of the application.

⚠️ **All screenshots Fastlane lanes must be executed from a Swiss IP, to avoid geo-blocking icons on media items.**

On a Mac device, with the latest version of Xcode and Fastlane installed:

1. Checkout the `main` branch.
2. Run the following commands:
   - Screenshots iOS:
       - Play RSI iOS: `fastlane ios iOSrsiScreenshots`
       - Play RTR iOS: `fastlane ios iOSrtrScreenshots` (No upload to ASC, due to some marketing images)
       - Play RTS iOS: `fastlane ios iOSrtsScreenshots` (No upload to ASC, due to some marketing images)
       - Play SRF iOS: `fastlane ios iOSsrfScreenshots` (No upload to ASC, due to some marketing images)
   - Screenshots tvOS:
       - Play RSI tvOS: `fastlane ios tvOSrsiScreenshots`
       - Play RTR tvOS: `fastlane ios tvOSrtrScreenshots` (No upload to ASC, due to some marketing images)
       - Play RTS tvOS: `fastlane ios tvOSrtsScreenshots` (No upload to ASC, due to some marketing images)
       - Play SRF tvOS: `fastlane ios tvOSsrfScreenshots` (No upload to ASC, due to some marketing images)
   - The screenshots are done with UITests scripts.
   - If allowed, the screenshots are uploaded to App Store Connect and replaced the current ones.
   - The screenshots are not yet submitted to Apple review.

ℹ️ Locally, the screenshots are in the `"fastlane/export/XxxYyyScreenshots` folder.

# Submit an App Store release for review

🙋**It's recommended to have the markdown [release checklist](RELEASE_CHECKLIST.md) in a shared Jira ticket or github issue to follow steps.** 

⚠️ **Never release a build from a feature branch. It must be merged to the `main` branch before.**

When all is ok:

- The what's new App Store release notes are translated on crowdin.com.
  - Sometimes, we need to fix returned lines, points po remove a translated line only for a BU application.
  - [Prepare an App Store release](#prepare-an-app-store-release) can be rerun to update the App Store release notes.
  - We can follow updated translations locally with `make appstore-status`.
- At least, one AppStore build is uploaded to App Store Connect for this version.
- The App Store screenshots are updated if needed.
- The App Store builds are validated by the team and the PO, using the Public Betas builds (named also AppStore builds).

Let's submit the App Store release for review:

1. Check translations locally with `make appstore-status`.
2. On PlayCity CI select the project:
   - **[Play SRG iOS AppStore releases](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgIOSAppStoreReleases)**: `fastlane ios iOSPrepareAppStoreReleases submit_for_review:true`
   - **[Play SRG tvOS AppStore releases](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgTvOSAppStoreReleases)**: `fastlane ios tvOSPrepareAppStoreReleases submit_for_review:true`
3. "Run" the project to open the dialog view.
4. In the *Parameters* tab, check the `submit_for_review` parameter.
5. In the *Parameters* tab, set the `tag_version` parameter (`X.Y.Z-N`) to use, if the version and build number on `main` branch are not the expected one (**should be the case**).
6. "Run build" from the dialog view. The script:
   - Creates a new App Store release on App Store Connect with the current version if not already existing.
   - Sets the translated what's new for this version.
   - Updates the what's new App Store release notes with the translated release notes from crowdin.com.
   - Does some basic metadata checks with [Fastlane precheck](https://docs.fastlane.tools/actions/precheck/).
   - The build related to the tag version is submitted to Apple review (build number from the `tag_version` parameter in the dialog view).
   - 🚀 Submission to Apple review is done this time.
   - *Automatically release this version* is set, to automatically release it after it has been approved by Apple App Review.
7. We can follow Apple release status and what's new release notes locally with `make appstore-status`.

# Follow App Store release status

Now, it's in Apple App Review team hands. Any Apple Ids linked to applications on App Store Connect will receive by email status update.

Locally, on a Mac, running `make appstore-status` give the current status for all Play SRG applications on App Store Connect.

ℹ️ The script is also scheduled to run on CI automatically.

1. On PlayCity CI select the project:
 	- **[Play SRG AppStore status](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgAppStoreStatus)**: `fastlane ios appStoreAppStatus github_deployments:true publish_release_notes:true`
2. Select the `main` branch (should be already selected).
3. Run the project. The script:
	- Gets AppStore live versions.
	- Gets lastest AppStore versions (can be the new submitted one or the live one).
	- checkes that the lastest AppStore version is different as the live version. Then the script:
		- Updates Github production deployment according to the last AppStore release state.
		- Displays in the console, live and latests versions, build number , current release state, and what's new.
		- Runs `fastlane ios publishReleaseNotes` if a Github production deployment state has switched to `success`. (see [Release notes on Github pages](#release-notes-on-github-pages))

```mermaid
---
title: Follow App Store release status
---
sequenceDiagram
    participant Fastlane
    participant ASC as App Store Connect
    Fastlane->>ASC: Ask live version
    activate Fastlane
	activate ASC
	ASC-->>Fastlane: Get live version
	deactivate ASC
	Fastlane->>Github: Ask production deployment state
	activate Github
	Github-->>Fastlane: Get production deployment state
    deactivate Github
	Fastlane->>Github: Update production deployment state if needed
    Fastlane->>ASC: Ask latest version
	activate ASC
	ASC-->>Fastlane: Get latest version
	deactivate ASC
	Fastlane->>Github: Update production deployment state if needed
    Fastlane->>Github: Push new gh-page with release notes if needed
	deactivate Fastlane
```

ℹ️ To learn more about Github deployments, see [Github environments and deployments](GITHUB_ENVIRONMENTS_AND_DEPLOYMENTS.md).

# Release notes on Github pages

Play SRG iOS applications have in `Profile` tab, `Settings` view, a `What's new` link.
It downloads a html file to display release notes. The html pages are published on the project Github pages: [https://srgssr.github.io/playsrg-apple](https://srgssr.github.io/playsrg-apple).

Publish release notes on Github pages with correct released status (App Store and TestFlight release notes):

ℹ️ The script is scheduled to run on CI after a private or public beta build success, also when an AppStore release is found with the [Play SRG AppStore status](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgAppStoreStatus) check.

1. On PlayCity CI select the project:
   - **[Play SRG Publish release notes](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgPublishReleaseNotes)**: `fastlane ios publishReleaseNotes`
2. Run the project. The script:
     - Gets translated whats's new from Crowdin.
     - Gets live version from App Store Connect.
     - Force pushes updated pages to the `gh-pages` branch.
     - Can be run from any branch. No dependency with versions or build numbers.

The update can be done manually (not recommended), without keeping the commits history on the `gh-pages` branch:

- Checkout `gh-pages` branch.
- Edit html files with a new `div` for a new version.
- Add or remove the `preprod` div attribute if it's a prerelease version (used by the javascript script).
- Amend commit with the changes.
- Force push the remote branch.
- Switch back to another branch.
- Remove local `gh-pages` branch (recommended if the fastlane script needs to run later).

```mermaid
---
title: Release notes on Github pages
---
sequenceDiagram
    Fastlane->>Crowdin: Ask what's new translated csv files
    activate Fastlane
	activate Crowdin
	Crowdin-->>Fastlane: Get what's new translated csv files
	deactivate Crowdin
    participant ASC as App Store Connect
    Fastlane->>ASC: Ask live version
    activate Fastlane
	activate ASC
	ASC-->>Fastlane: Get live version
	deactivate ASC
	Fastlane->>Github: Publish new gh-pages
	deactivate Fastlane
```

# Bump platform version after a release

When a release is published on the App Store, the version number (`X.Y.Z`) needs to be bumped for the next release.

ℹ️ The script is scheduled to run on CI automatically.

1. On PlayCity CI select the project:
 	- **[Play SRG After AppStore release](https://playcity.eu.ngrok.io/buildConfiguration/playsrgios_PlaySrgAfterAppStoreRelease)**: `fastlane ios afterAppStoreRelease`
2. Select the `main` branch (should be already selected).
3. Run the project. The script:
	- Get AppStore live versions.
	- If one live version is same as the current marketing version, the script:
		- Bumps the patch number of version number (`X.Y.Z`) on the repository.
		- Commits the version bump with message "Bump version to `X.Y.Z+1`".
		- Pushes the commit to the repository.

```mermaid
---
title: Bump versions
---
%%{init: { 'themeVariables': {
    'git0': '#af001e', 'gitBranchLabel0': '#ffffff', 'gitInv0': '#af001e',
    'git1': '#0f5acb', 'gitBranchLabel0': '#ffffff', 'gitInv1': '#0f5acb',
    'commitLabelColor': '#d2d2d2', 'commitLabelBackground': '#232323',
    'tagLabelColor': '#ffffff', 'tagLabelBackground': '#8b0019'
} } }%%
gitGraph  TB:
    checkout main
    commit id: "JIRA-1234 Feature A (#456)"
    commit tag: "tag [ios|tvOS]/X.Y.Z-N" id: "Update what's new"
    commit id: "Bump build number to N+1"
    commit id: "Bump [iOS|tvOS] version to X.Y.Z+1" type: HIGHLIGHT
```
