#!/usr/bin/env bash
set -euo pipefail

PROJECT="Github Contribution Widget.xcodeproj"
SCHEME="Github Contribution Widget"
CONFIGURATION="Debug"
DERIVED_DATA_PATH=".build/DerivedData"
APP_NAME="GitHub Contribution Widget"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

if pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
  pkill -x "${APP_NAME}"
fi

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "platform=macOS" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ "${1:-}" == "--verify" ]]; then
  echo "Built ${APP_PATH}"
  exit 0
fi

/usr/bin/open -n "${APP_PATH}"
