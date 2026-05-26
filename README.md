# Github Contribution Widget

## Token Storage

The GitHub Personal Access Token is stored in the macOS Keychain, not in shared
UserDefaults. The app and widget extension both declare the same Keychain
Sharing access group so the widget can read the token when the signed app has
that entitlement available.

If WidgetKit cannot access the Keychain item at runtime, the widget does not
surface the failure or expose the token. It safely falls back to mock
contribution data.
