# GitHub Contribution Widget

Minimal macOS SwiftUI + WidgetKit app for a glassy GitHub contribution widget.

## Screenshots

Screenshots will be added after the first signed local run with the widget
installed on the desktop.

## Setup

1. Open `Github Contribution Widget.xcodeproj` in Xcode.
2. Select the `Github Contribution Widget` scheme.
3. Set your development team for both the app target and widget extension.
4. Confirm both targets keep the same App Group and Keychain Sharing group.
5. Build and run the macOS app.
6. Open the app settings, enter your GitHub username, paste a Personal Access
   Token, choose a year, then click `Refresh Widget`.

## Creating A GitHub Token

1. Open GitHub token settings from the app or visit `https://github.com/settings/tokens`.
2. For public contribution counts, create any Personal Access Token that can use
   the GitHub GraphQL API.
3. For profile totals that include private/internal contributions, create a
   **Personal access token (classic)** with the `read:user` scope. GitHub's
   GraphQL `ContributionsCollection` documents private and internal
   contributions as requiring this optional scope; fine-grained PATs do not
   expose a direct `read:user` scope and may return public-only totals.
4. Copy the token once and paste it into the app settings.
5. Keep the token read-only for contribution data; do not grant write
   access unless you need it for another workflow.

## Adding The Widget

1. Run the app once after signing is configured.
2. Open Notification Center or the desktop widget gallery.
3. Search for `GitHub Contributions`.
4. Add the medium or large widget.
5. Return to the app settings and click `Refresh Widget` after changing
   username, token, or year.

## Token Storage

The GitHub Personal Access Token is stored in the macOS Keychain, not in shared
UserDefaults. The app and widget extension both declare the same Keychain
Sharing access group so the widget can read the token when the signed app has
that entitlement available.

If WidgetKit cannot access the Keychain item at runtime, the widget does not
surface the failure or expose the token. It safely falls back to mock
contribution data.

## Troubleshooting

- If the widget shows mock data, open app settings and check that username,
  token, and year are valid.
- If Keychain reads fail in the widget, verify the app and widget extension have
  the same Keychain Sharing access group and are signed with the same team.
- If settings do not reach the widget, verify the App Group identifier matches
  in both entitlements files and in `GitHubSettings.appGroupIdentifier`.
- If the widget does not refresh immediately, click `Refresh Widget`, remove and
  re-add the widget, or rebuild and run the app once from Xcode.
- If GitHub fetch fails, create a new token and make sure the account can access
  the requested contribution year.
- If Test Fetch shows fewer contributions than your GitHub profile, your token
  is probably returning public contribution counts only. Use a classic PAT with
  `read:user` if you want private contribution counts included.
