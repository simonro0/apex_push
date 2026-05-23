/// Strava API credentials for ApexPush.
///
/// Setup (one-time, free):
///   1. Go to https://www.strava.com/settings/api
///   2. Create an app (any name / website)
///   3. Set "Authorization Callback Domain" to: apexpush
///   4. Copy Client ID and Client Secret into the constants below.
///
/// Without valid credentials the Strava integration is disabled in the UI.
class StravaConfig {
  // ─── Fill in your own values ──────────────────────────────────────────────
  static const clientId     = 'YOUR_CLIENT_ID';
  static const clientSecret = 'YOUR_CLIENT_SECRET';
  // ─────────────────────────────────────────────────────────────────────────

  /// OAuth2 redirect URI – must match the appAuthRedirectScheme in build.gradle.kts
  /// and the Strava callback domain set on https://www.strava.com/settings/api.
  static const redirectUri  = 'apexpush://oauth2/callback';
  static const scopes       = ['activity:write'];

  static const _authEndpoint  = 'https://www.strava.com/oauth/mobile/authorize';
  static const _tokenEndpoint = 'https://www.strava.com/oauth/token';
  static const apiBase        = 'https://www.strava.com/api/v3';

  static String get authorizationEndpoint => _authEndpoint;
  static String get tokenEndpoint         => _tokenEndpoint;

  /// True when actual credentials have been configured (not the placeholder).
  static bool get isConfigured =>
      clientId != 'YOUR_CLIENT_ID' && clientSecret != 'YOUR_CLIENT_SECRET';
}
