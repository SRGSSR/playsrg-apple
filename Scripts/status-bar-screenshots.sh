#!/usr/bin/env bash

xcrun simctl boot "${TARGET_DEVICE_IDENTIFIER}"

xcrun simctl status_bar "${TARGET_DEVICE_IDENTIFIER}" override \
    --time "2020-01-01T09:41:00+0100" \
    --dataNetwork "wifi" \
    --wifiMode "active" \
    --wifiBars "3" \
    --cellularMode "notSupported" \
    --batteryState "charged" \
    --batteryLevel "100"