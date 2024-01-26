#!/bin/bash

# Set the directory paths
project_directories=("Application" "TV Application" "Extensions")
output_directory="Translations"


# Generate the Localizable.strings file
mkdir -p "$output_directory/Localizable"

find "${project_directories[@]}" -type f \( -name "*.m" -o -name "*.swift" \) -exec genstrings -s NSLocalizedString -q -o "$output_directory/Localizable" {} +
iconv -f UTF-16LE -t UTF-8 "$output_directory/Localizable/Localizable.strings" > "$output_directory/Localizable/Localizable_UTF8.strings"

mv -f "$output_directory/Localizable/Localizable_UTF8.strings" "$output_directory/Localizable.strings"
rm -Rf "$output_directory/Localizable"

# Generate the Accessibility.strings file
mkdir -p "$output_directory/Accessibility"

find "${project_directories[@]}" -type f \( -name "*.m" -o -name "*.swift" \) -exec sed -i '' 's/NSLocalizedString(/NotAccessibilityNSLocalizedString(/g' {} +

find "${project_directories[@]}" -type f \( -name "*.m" -o -name "*.swift" \) -exec genstrings -s PlaySRGAccessibilityLocalizedString -q -o "$output_directory/Accessibility" {} +
iconv -f UTF-16LE -t UTF-8 "$output_directory/Accessibility/Localizable.strings" > "$output_directory/Accessibility/Localizable_UTF8.strings"

find "${project_directories[@]}" -type f \( -name "*.m" -o -name "*.swift" \) -exec sed -i '' 's/NotAccessibilityNSLocalizedString(/NSLocalizedString(/g' {} +

mv -f "$output_directory/Accessibility/Localizable_UTF8.strings" "$output_directory/Accessibility.strings"
rm -Rf "$output_directory/Accessibility"