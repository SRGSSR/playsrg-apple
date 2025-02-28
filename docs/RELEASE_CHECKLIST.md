# Release checklist

The checklist is a markdown list which can be copy and past in a Jira ticket Smart Checklist or a Github issue.

```
# Prepare release on Git branch
-! Verify that `Package.resolved` (SPM) / `Podfile.lock` (CocoaPods) only contain tagged versions
-! Update application translations (with `make pull-translations`)
> Then commit on branch and make a PR.
> Wait PR review and merge when ready.
-! Perform global diff with last release tag
> Check all is ok for an App Store release.


# Prepare release on App Store Connect
- Follow [Prepare an App Store release](https://github.com/SRGSSR/playsrg-apple/blob/main/docs/WORKFLOWS.md#prepare-an-app-store-release) worflow.
-! Downloads (iOS|tvOS) what's new CSVs from Crowdin, add version number line at the bottom with an english text.
-! Upload updated (iOS|tvOS) what's new CSVs and ask for translations by email.
> Ask the translators ([play-srg-translators@rts.ch](mailto:play-srg-translators@rts.ch)) to translate the new entries.
-! Create new (iOS|tvOS) version on App Store Connect (with fastlane on CI)
> [Prepare an App Store release](https://github.com/SRGSSR/playsrg-apple/blob/main/docs/WORKFLOWS.md#prepare-an-app-store-release) worflow.
- Update (iOS|tvOS) screenshots if needed (with fastlane locally)
> [Update the App Store screenshots](https://github.com/SRGSSR/playsrg-apple/blob/main/docs/WORKFLOWS.md#update-the-app-store-screenshots)

# Build versions
-! If a Private Beta build aldready exist, check if new commits after this latest beta tag. If not, it's best to use this existing tag.
- Build (iOS|tvOS) App Store builds (with fastlane on CI)
> If a Private Beta has not been built yet, commit to the `main` branch with message "PLAYNEXT-XXXX Update what's new", including an update to the `WhatsNew-iOS-beta.json` and `WhatsNew-tvOS-beta.json` files with an incremented build number.
> [Build and distribute Public Betas and AppStore Builds](https://github.com/SRGSSR/playsrg-apple/blob/main/docs/WORKFLOWS.md#build-and-distribute-public-betas-and-appstore-builds)
> It will schedule Private Beta as well if not yet built and creates new tags, if not already exist.
-! Update (iOS|tvOS) production remote configuration on Firebase.

# Submit to Apple review
-! Check what's new App Store release notes are translated on crowdin
-! Submit to Apple review the new (iOS|tvOS) version on App Store Connect (with fastlane on CI)
> [Submit an App Store release for review](https://github.com/SRGSSR/playsrg-apple/blob/main/docs/WORKFLOWS.md#submit-an-app-store-release-for-review)
> The "what's new" content for the App Store is automatically retrieved from Crowdin.
-! Check all versions have the correct build number and state changed to "waiting for review"
> The status for the 4 BUs and 2 platforms can be check with `make appstore-status`.

# Check validation
-! 📱 Obtain successful Apple review and release Play RSI iOS
-! 📱 Obtain successful Apple review and release Play RTR iOS
-! 📱 Obtain successful Apple review and release Play RTS iOS
-! 📱 Obtain successful Apple review and release Play SRF iOS
-! 📺 Obtain successful Apple review and release Play RSI tvOS
-! 📺 Obtain successful Apple review and release Play RTR tvOS
-! 📺 Obtain successful Apple review and release Play RTS tvOS
-! 📺 Obtain successful Apple review and release Play SRF tvOS

# Finish release
-! 📱 Create iOS Github release with the released tag
> https://github.com/SRGSSR/playsrg-apple/releases
> Auto generate the text from the last released tag
-! 📺 Create tvOS Github release with the released tag
> https://github.com/SRGSSR/playsrg-apple/releases
> Auto generate the text from the last released tag
```

# AppStore and TestFlight review status

On a local device, we can get AppStore review status and public TestFlight review status:

- First, but sure that `make ruby-setup` has been run to setup Ruby.
- Get AppStore review status (Ready for sale, In review, etc…)
	- `make appstore-status`
- Get public TestFlight review status (In beta testing, In review, etc…)
	- `make appstore-testflight-status`

