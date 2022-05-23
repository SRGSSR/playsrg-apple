# Configuration files

The Play project is configured with a hierarchy of `xcconfig` files to avoid redundancy and ensure consistency. Before editing these configuration files, either to add a new parameter or target or to edit existing settings, please have a look at the present guide to ensure your changes are compatible with the existing setup.

## Structure

The `xcconfig` files are located under the `Xcode` directory, structured as follows:

- `Shared/`: Set of configuration files which contain shared settings:
    - `Common.xcconfig`: The top-level configuration settings.
    - `BUs/`: BU specific settings.
    - `Target/`: Target-specific settings.
        - `iOS/`: iOS target settings.
            - `Common.xcconfig`: Settings common to all iOS targets.
            - `Application.xcconfig`: iOS application settings.
            - `Notification Service Extension.xcconfig`: iOS notification service extension settings.
            - `Screenshots.xcconfig`: iOS screenshots UI testing bundle settings.
        - `tvOS/`: tvOS target settings. 
            - `Common.xcconfig`: Settings common to all iOS targets.
            - `Application.xcconfig`: tvOS application settings
            - `Screenshots.xcconfig`: tvOS screenshots UI testing bundle settings.
- `iOS` / `tvOS`: Set of leaf configuration files, grouped per platform and target type. These files `#import` shared configuration files but do not define parameters on their own. They import shared configuration files first, then CocoaPods configuration files, so that no `$(inherited)` is required for settings defined in shared configuration files.

### Configuration support

There are no configuration-specific configuration files. If you need to adjust settings per configuration use the dedicated Xcode syntax:

```
PARAMETER[config=Beta] = Value for the beta configuration
```

## Configuration file edition

When you need to edit configuration files, either to change or add settings or when creating a new target type, please follow the instructions below.

### Adding a new target type

When adding a new target type:

1. Add a dedicated `xcconfig` file to the `Shared/Target/(iOS|tvOS)` folder associated with its platform.
2. Import the `Shared/Target/(iOS|tvOS)/Common.xcconfig` platform configuration file from the newly added configuration file.
3. Create as many leaf configuration files as needed in the top-level `iOS` or `tvOS` directories, within a directory matching the type of the target you added. Refer to existing setups to find whether a few configuration files suffice or if you need to create different configuration files for each configuration (debug, nightly, beta, etc.).
4. Edit each leaf file and `#include` the shared and CocoaPods configuration files required. Leaf configuration files should only contain includes and must not define parameters on their own.
5. In Xcode, under the _General_ tab for your project, associate each configuration file with your new targets.

### Adding settings

Settings must be added to configuration files locatd in the `Shared` directory to ensure a consistent setup:

1. Consider at which level your parameter must be added:
    - If the parameter does not depend on the BU or the target, add it to the top-level `Shared/Common.xcconfig`.
    - If the parameter is BU-specific, add it to configuration files in the `Shared/BUs` directory.
    - If the parameter is target-specific, add it to configuration files in the `Shared/Targets` directory.
2. Pick an appropriate name for your setting and add it to all involved files at the level you chose. Please observe the following rules:
    - Custom settings must be prefixed to make them easier to distinguish from official Xcode build settings. The prefix must reflect to where the parameter is found in configuration file hierarchy:
        - Top-level common settings in `Shared/Common.xcconfig` must be prefixed with `COMMON__`.
        - Target-specific settings must be prefixed with `TARGET__`. Common settings in `Shared/Target/Common.xcconfig` must be prefixed with `TARGET_COMMON__`.
        - BU-specific settings must be prefixed with `BU__`.
    - If your setting value starts with a space, use a leading `$()` to preserve it:
        ```
        PARAMETER_WITH_LEADING_SPACE = $() and the rest
        ```
3. Use the new settings where needed in your project. You can either use the parameter directly or use it as a building block for other settings (see _Settings hierarchy_ below).

## Settings hierarchy

Settings must never be overridden by several configuration files involved in the same `#include` hierarchy. But settings can be used in a parent configuration file even if they are only defined in their descendents. This makes it possible to define parameters in ancestor configuration files, made of a combination of parameters only defined by their descendents.

The `PRODUCT_BUNDLE_IDENTIFIER` is a good example of such a parameter. It is namely defined in the top-level `Shared/Common.xcconfig` file but is itself made of other common, BU and target-specific settings. The top-level common configuration file therefore provides the recipe for the parameter format, while its descendents provide the actual ingredients required to build it.

# Exclude packages per configuration

Swift Package Manager does not offer a way to exclude packages per configuration, but there is a workaround using Xcode settings. As documented in [FLEX installation guide](https://github.com/FLEXTool/FLEX), it namely suffices to use `INCLUDED_SOURCE_FILE_NAMES` and `EXCLUDED_SOURCE_FILE_NAMES` to exclude some packages for specific configurations.

If needed identify the target which requires package exclusion and edit its associated configuration file accordingly. For a package which should never be delivered in production by mistake please ensure the package is **excluded as a general rule and included only for the configurations needing it**.