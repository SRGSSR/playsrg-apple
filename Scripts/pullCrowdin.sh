#! /bin/sh

if ! command -v crowdin > /dev/null; then
    echo "crowdin CLI is not available. Please install it. https://crowdin.github.io/crowdin-cli/installation"
    exit 0
fi

# Get the directory of the script
script_dir="$(dirname "$(readlink -f "$0")")"

# Load the repository .env file
ENV_FILE="$script_dir/../.env"
if [ -f "$ENV_FILE" ]; then
# shellcheck source=/dev/null
	. "$ENV_FILE"
fi

if [ -z "$CROWDIN_API_TOKEN" ]; then
	echo "CROWDIN_API_TOKEN environment variable is not set. Skipping Crowdin pulling."
	exit 0
fi

rm -rf /tmp/playsrg-crowdin
mkdir /tmp/playsrg-crowdin

# Use the repository configuration file
CROWDIN_CONFIG_FILE="$script_dir/../crowdin.yml"

# crowdin CLI needs sources in the current directory to get translations.
echo "Downloading sources from Crowdin..."
crowdin pull sources -c "$CROWDIN_CONFIG_FILE" --token "$CROWDIN_API_TOKEN" --no-progress

# crowdin CLI builds ZIP archive with the latest translations automatically.
echo "Downloading the latest translations..."
crowdin pull -c "$CROWDIN_CONFIG_FILE" --token "$CROWDIN_API_TOKEN" --no-progress

for i in "$@"
do
	if [ "$i" = "--skip-copies" ]; then
        exit 0
	fi
done

if [ -z "$CROWDIN_PLAY_PATH" ]; then
	CROWDIN_PLAY_PATH="."
	echo "Use default CROWDIN_PLAY_PATH variable: \".\""
fi

if [ -z "$CROWDIN_MEDIA_PLAYER_PATH" ]; then
	CROWDIN_MEDIA_PLAYER_PATH="../srgmediaplayer-apple"
	echo "Use default CROWDIN_MEDIA_PLAYER_PATH variable: \"$CROWDIN_MEDIA_PLAYER_PATH\""
fi

if [ -z "$CROWDIN_NETWORK_PATH" ]; then
	CROWDIN_NETWORK_PATH="../srgnetwork-apple"
	echo "Use default CROWDIN_NETWORK_PATH variable: \"$CROWDIN_NETWORK_PATH\""
fi

if [ -z "$CROWDIN_IDENTITY_PATH" ]; then
	CROWDIN_IDENTITY_PATH="../srgidentity-apple"
	echo "Use default CROWDIN_IDENTITY_PATH variable: \"$CROWDIN_IDENTITY_PATH\""
fi

if [ -z "$CROWDIN_CONTENT_PROTECTION_PATH" ]; then
	CROWDIN_CONTENT_PROTECTION_PATH="../srgcontentprotection-apple"
	echo "Use default CROWDIN_CONTENT_PROTECTION_PATH variable: \"$CROWDIN_CONTENT_PROTECTION_PATH\""
fi

if [ -z "$CROWDIN_DATA_PROVIDER_PATH" ]; then
	CROWDIN_DATA_PROVIDER_PATH="../srgdataprovider-apple"
	echo "Use default CROWDIN_DATA_PROVIDER_PATH variable: \"$CROWDIN_DATA_PROVIDER_PATH\""
fi

if [ -z "$CROWDIN_LETTERBOX_PATH" ]; then
	CROWDIN_LETTERBOX_PATH="../srgletterbox-apple"
	echo "Use default CROWDIN_LETTERBOX_PATH variable: \"$CROWDIN_LETTERBOX_PATH\""
fi

if [ -z "$CROWDIN_USER_DATA_PATH" ]; then
	CROWDIN_USER_DATA_PATH="../srguserdata-apple"
	echo "Use default CROWDIN_USER_DATA_PATH variable: \"$CROWDIN_USER_DATA_PATH\""
fi

# Play applications
echo "Update Play SRG translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/Play App/Localizable.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SRF/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/Play App/Localizable.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTS/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/Play App/Localizable.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RSI/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/Play App/Localizable.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTR/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/Play App/Localizable.strings"    "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SWI/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/Play App/Accessibility.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SRF/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/Play App/Accessibility.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTS/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/Play App/Accessibility.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RSI/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/Play App/Accessibility.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTR/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/Play App/Accessibility.strings"    "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SWI/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/Play App/Onboarding.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SRF/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/Play App/Onboarding.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTS/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/Play App/Onboarding.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RSI/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/Play App/Onboarding.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTR/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/Play App/Onboarding.strings"    "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SWI/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/Play App/InfoPlist.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SRF/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/Play App/InfoPlist.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTS/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/Play App/InfoPlist.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RSI/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/Play App/InfoPlist.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play RTR/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/Play App/InfoPlist.strings"    "$CROWDIN_PLAY_PATH/Application/Resources/Apps/Play SWI/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/Play App/Settings.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Settings.bundle/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/Play App/Settings.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Settings.bundle/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/Play App/Settings.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Settings.bundle/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/Play App/Settings.strings" "$CROWDIN_PLAY_PATH/Application/Resources/Settings.bundle/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/Play App/Settings.strings"    "$CROWDIN_PLAY_PATH/Application/Resources/Settings.bundle/en.lproj/"

# SRG Media Player library
Echo "Update SRG Media Player translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGMediaPlayer Library/Localizable.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGMediaPlayer Library/Localizable.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGMediaPlayer Library/Localizable.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGMediaPlayer Library/Localizable.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGMediaPlayer Library/Localizable.strings"    "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGMediaPlayer Library/Accessibility.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGMediaPlayer Library/Accessibility.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGMediaPlayer Library/Accessibility.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGMediaPlayer Library/Accessibility.strings" "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGMediaPlayer Library/Accessibility.strings"    "$CROWDIN_MEDIA_PLAYER_PATH/Sources/SRGMediaPlayer/Resources/en.lproj/"

# SRG Network library
echo "Update SRG Network translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGNetwork Library/Localizable.strings" "$CROWDIN_NETWORK_PATH/Sources/SRGNetwork/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGNetwork Library/Localizable.strings" "$CROWDIN_NETWORK_PATH/Sources/SRGNetwork/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGNetwork Library/Localizable.strings" "$CROWDIN_NETWORK_PATH/Sources/SRGNetwork/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGNetwork Library/Localizable.strings" "$CROWDIN_NETWORK_PATH/Sources/SRGNetwork/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGNetwork Library/Localizable.strings"    "$CROWDIN_NETWORK_PATH/Sources/SRGNetwork/Resources/en.lproj/"

# SRG Identity library
echo "Update SRG Identity translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGIdentity Library/Localizable.strings" "$CROWDIN_IDENTITY_PATH/Sources/SRGIdentity/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGIdentity Library/Localizable.strings" "$CROWDIN_IDENTITY_PATH/Sources/SRGIdentity/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGIdentity Library/Localizable.strings" "$CROWDIN_IDENTITY_PATH/Sources/SRGIdentity/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGIdentity Library/Localizable.strings" "$CROWDIN_IDENTITY_PATH/Sources/SRGIdentity/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGIdentity Library/Localizable.strings"    "$CROWDIN_IDENTITY_PATH/Sources/SRGIdentity/Resources/en.lproj/"

# SRG Content Protection library
echo "Update SRG Content Protection translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGContentProtection Library/Localizable.strings" "$CROWDIN_CONTENT_PROTECTION_PATH/Sources/SRGContentProtection/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGContentProtection Library/Localizable.strings" "$CROWDIN_CONTENT_PROTECTION_PATH/Sources/SRGContentProtection/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGContentProtection Library/Localizable.strings" "$CROWDIN_CONTENT_PROTECTION_PATH/Sources/SRGContentProtection/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGContentProtection Library/Localizable.strings" "$CROWDIN_CONTENT_PROTECTION_PATH/Sources/SRGContentProtection/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGContentProtection Library/Localizable.strings"    "$CROWDIN_CONTENT_PROTECTION_PATH/Sources/SRGContentProtection/Resources/en.lproj/"

# SRG Data Provider library
echo "Update SRG Data Provider translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGDataprovider Library/Localizable.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGDataprovider Library/Localizable.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGDataprovider Library/Localizable.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGDataprovider Library/Localizable.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGDataprovider Library/Localizable.strings"    "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGDataprovider Library/Accessibility.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGDataprovider Library/Accessibility.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGDataprovider Library/Accessibility.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGDataprovider Library/Accessibility.strings" "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGDataprovider Library/Accessibility.strings"    "$CROWDIN_DATA_PROVIDER_PATH/Sources/SRGDataProviderModel/Resources/en.lproj/"

# SRG Letterbox library
Echo "Update SRG Letterbox translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGLetterbox Library/Localizable.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGLetterbox Library/Localizable.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGLetterbox Library/Localizable.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGLetterbox Library/Localizable.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGLetterbox Library/Localizable.strings"    "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/en.lproj/"

cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGLetterbox Library/Accessibility.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGLetterbox Library/Accessibility.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGLetterbox Library/Accessibility.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGLetterbox Library/Accessibility.strings" "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGLetterbox Library/Accessibility.strings"    "$CROWDIN_LETTERBOX_PATH/Sources/SRGLetterbox/Resources/en.lproj/"

# SRG User Data library
echo "Update SRG User Data translations files."
cp -f "/tmp/playsrg-crowdin/de-CH/Apple/SRGUserData Library/Localizable.strings" "$CROWDIN_USER_DATA_PATH/Sources/SRGUserData/Resources/de.lproj/"
cp -f "/tmp/playsrg-crowdin/fr-CH/Apple/SRGUserData Library/Localizable.strings" "$CROWDIN_USER_DATA_PATH/Sources/SRGUserData/Resources/fr.lproj/"
cp -f "/tmp/playsrg-crowdin/it-CH/Apple/SRGUserData Library/Localizable.strings" "$CROWDIN_USER_DATA_PATH/Sources/SRGUserData/Resources/it.lproj/"
cp -f "/tmp/playsrg-crowdin/rm-CH/Apple/SRGUserData Library/Localizable.strings" "$CROWDIN_USER_DATA_PATH/Sources/SRGUserData/Resources/rm.lproj/"
cp -f "/tmp/playsrg-crowdin/en/Apple/SRGUserData Library/Localizable.strings"    "$CROWDIN_USER_DATA_PATH/Sources/SRGUserData/Resources/en.lproj/"
