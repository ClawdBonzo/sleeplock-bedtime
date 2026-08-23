#!/bin/bash
SIM=BD99E24A-6C24-4428-A5F4-5D78FAB19218
APP=/Users/robgoldstein/Desktop/SleepLock/build/dd/Build/Products/Debug-iphonesimulator/SleepLock.app
B=com.clawdbonzo.SleepLock
OUT=/Users/robgoldstein/Desktop/SleepLock/screenshots/raw
xcrun simctl install $SIM $APP
xcrun simctl status_bar $SIM override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3
for lang in en es pt-BR fr it de nl ja ko sv; do
  mkdir -p $OUT/$lang
  for spec in "01-bedtime|-StartTab|0" "02-streaks|-StartTab|2" "03-levelup|-StartTab|1" "04-analytics|-ShowAnalytics|1"; do
    IFS='|' read -r f k v <<< "$spec"
    xcrun simctl terminate $SIM $B 2>/dev/null
    xcrun simctl launch $SIM $B -SeedDemoData 1 -ForcePremium 1 -SkipLaunchPaywall 1 $k $v -AppleLanguages "($lang)" -AppleLocale "$lang" >/dev/null 2>&1
    sleep 7
    xcrun simctl io $SIM screenshot $OUT/$lang/$f.png >/dev/null 2>&1
  done
  echo "captured $lang"
done
xcrun simctl terminate $SIM $B 2>/dev/null
echo DONE
