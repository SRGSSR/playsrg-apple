# Github environments and deployments

When building binaries with the [fastlane lanes](RELEASE_CHECKLIST.md#fastlane-on-playcity-ci), if a `GITHUB_TOKEN` environment variable is set with a valid write access token to [playsrg-apple](https://github.com/SRGSSR/playsrg-apple) Github repository, [environments and deployments](https://github.com/SRGSSR/playsrg-apple/deployments) are created.

## Environments

-  The `fastlane ios iOSnightlies` lane uses `playsrg-ios-nighty[+branch_name]` environments*.
-  The `fastlane ios tvOSnightlies` lane uses `playsrg-tvos-nighty[+branch_name]` environments*.
-  The `fastlane ios iOSbetas` lane uses `playsrg-ios-beta[+branch_name]` environments*.
-  The `fastlane ios tvOSbetas` lane uses `playsrg-tvos-beta[+branch_name]` environments*.
-  The `fastlane ios iOSAppStoreBuilds` lane uses `playsrg-ios-testflight[+branch_name]` environments*.
-  The `fastlane ios tvOSAppStoreBuilds` lane uses `playsrg-tvos-testflight[+branch_name]` environments*.

\*Branch name is added only if the git branch name includes `feature/`.

## Deployments

### Creation

When one of the listed fastlane lane above is executed, a new deployment is created:

- The reference (`ref`) is the git branch name, only if the deployment `sha` is same as the last commit hash on the branch, to be sure that it's link to the correct commit. If it's not the case, the deployment is deleted and a new deployment is created with the last commit hash as the reference.
- No `auto_merge` option.
- No `required_contexts` option.


### Update state

During a fastlane lane execution:

- the script can update the current Github deployment state to `in_progress`, `success` or `error`.
-  if the `BUILD_URL` environment variable is set, it's added to Github deployment information as `log_url`.
- if the deployment state switched to `success`, an help page url is added to Github deployment information as `environment_url`. The help page url for builds is like:
  - `https://srgssr.github.io/playsrg-apple/deployments/build.html?configuration=[nightly|beta|testflight|appstore]&platform=[ios|tvos]&version=[version_friendly_name]`.

### Unfinished issue

If the fastlane execution finished with an error, the Github deployment state should be set to `error`. But if the fastlane execution is killed with an exit signal, no state is applied and the Github deployment could stay in `in_progress` state.

An independant fastlane lane can help to **stop all unfinished** deployments for a lane which have a Github environement, applying the `error` state.

- `fastlane ios stopUnfinishedGithubDeployments lane:[LANE_NAME]`

