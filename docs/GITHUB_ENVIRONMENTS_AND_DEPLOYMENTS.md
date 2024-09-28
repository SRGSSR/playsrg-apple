# Github environments and deployments

When building binaries with the [fastlane build lanes](RELEASE_CHECKLIST.md#fastlane-on-playcity-ci), if a `GITHUB_TOKEN` environment variable is set with a valid write access token to [playsrg-apple](https://github.com/SRGSSR/playsrg-apple) Github repository, **non-production** [environments and deployments](https://github.com/SRGSSR/playsrg-apple/deployments) are created.

A dedicated [fastlane status lane](RELEASE_CHECKLIST.md#appstore-and-testflight-review-status) follows [App Store processes](https://developer.apple.com/ios/submit/) for submissions, reviews and publications. With a same valid `GITHUB_TOKEN` environment variable, **production** [environments and deployments](https://github.com/SRGSSR/playsrg-apple/deployments) can be created and have synchronized states with App Store Connect states.

## Environments

#### Non-production
-  The `fastlane ios iOSnightlies` lane uses `playsrg-ios-nighty[+branch_name]` environments*.
-  The `fastlane ios tvOSnightlies` lane uses `playsrg-tvos-nighty[+branch_name]` environments*.
-  The `fastlane ios iOSbetas` lane uses `playsrg-ios-beta[+branch_name]` environments*.
-  The `fastlane ios tvOSbetas` lane uses `playsrg-tvos-beta[+branch_name]` environments*.
-  The `fastlane ios iOSAppStoreBuilds` lane uses `playsrg-ios-testflight[+branch_name]` environments*.
-  The `fastlane ios tvOSAppStoreBuilds` lane uses `playsrg-tvos-testflight[+branch_name]` environments*.

\*Branch name is added only if the git branch name includes `feature/`.

#### Production
-  The `fastlane ios appStoreAppStatus github_deployments:true` lane uses:
	-  `playsrg-ios-appstore-[bu_name]` environments*.
	-  `playsrg-tvos-appstore-[bu_name]` environments*.

\*Business unit name is in lower case, 3 usual letters.

## Deployments

### Creation

Common deployment options:

- No `auto_merge` option.
- No `required_contexts` option.
- `auto_inactive` option enabled.

#### Non-production
When one of the listed fastlane lane above is executed, a new deployment is created.

- The reference (`ref`) is one of this option, tested in this order:
	- the last git tag name, only if the deployment `sha` is same as the last commit hash on the branch, to be sure that it's link to the correct commit.
	- the git branch name, only if the deployment `sha` is same as the last commit hash on the branch, to be sure that it's link to the correct commit.
	- If it's not the same commit `sha`, the new deployment is deleted and a new deployment is created with the last commit hash as the reference.
- `task` = `Build and distribute`.
- `production_environment` = `false`.

#### Production
For each App Store version information, if a build number is associated to a version, a new deployment is created, if it does not already exist.

- The reference (`ref`) is only this option:
	- the git tag name of the App Store version. No deployment is created if the git tag does not exist.
- `task` = `Distribute`.
- `production_environment` = `true`.

### Update state

Common deployment state options:

-  if the `BUILD_URL` environment variable is set, it's added to Github deployment information as `log_url`.
- if the deployment state switched to `success`, an help page url is added to Github deployment information as `environment_url`. The help page url for builds is like:
  - `https://srgssr.github.io/playsrg-apple/deployments/build.html?configuration=[nightly|beta|testflight|appstore]&platform=[ios|tvos]&version=[version_friendly_name]`.

#### Non-production
During a fastlane lane execution:

- the script can update the current Github deployment state to `in_progress`, `success` or `error`.

#### Production
At each fastlane lane execution:

- the script can update the current Github deployment state to `queued`, `in_progress`, `pending`, `success`, `inactive` or `error`.

### Unfinished issue

#### Non-production
If the fastlane execution finished with an error, the Github deployment state should be set to `error`. But if the fastlane execution is killed with an exit signal, no state is applied and the Github deployment could stay in `in_progress` state.

An independant fastlane lane can help to **stop all unfinished** deployments for a lane which have a Github environement. It's applying the `error` state.

- `fastlane ios stopUnfinishedGithubDeployments lane:[LANE_NAME]`

#### Production

If the fastlane execution finished with an error, or killed with an exit signal, run manually the lane again. By default, it uses an existing deployment and does not create a new one.

### Inactive state

- [By default](https://docs.github.com/en/rest/deployments/deployments?apiVersion=2022-11-28#inactive-deployments), the non-transient, non-production environment deployments created by fastlane scripts have `auto_inactive` = `true`. So that a new `success` deployment sets all previous `success` deployments to `inactive` state. It's also activated to production environment deployments because the App Store distribution only allows the latest version of the application.
- When closing a PR, a [Github action](https://github.com/SRGSSR/playsrg-apple/actions/workflows/pr-closure.yml) (pr-closure.yml) is updating state to `inactive` to lastest `success` deployment for nighty branch environnements and beta branch environnements.

