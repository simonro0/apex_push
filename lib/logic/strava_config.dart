/// Strava API credentials for ApexPush.
///
/// ## Setup (one-time, free)
///
/// 1. Go to https://www.strava.com/settings/api
/// 2. Create an app (any name, website can be anything, e.g. https://localhost)
/// 3. Set "Authorization Callback Domain" to: `apexpush`
/// 4. Copy Client ID and Client Secret into `strava.env.json`
///    (see `strava.env.json.example` in the project root)
///
/// ## Running / building
///
/// ```
/// flutter run   --dart-define-from-file=strava.env.json
/// flutter build --dart-define-from-file=strava.env.json
/// ```
///
/// In Android Studio: Edit Configurations → Additional run args →
///   `--dart-define-from-file=strava.env.json`
///
/// Without a valid `strava.env.json` the integration is silently disabled
/// in the UI (no Strava tile, no export button).
class StravaConfig {
  // Credentials are injected at compile time via --dart-define-from-file.
  // Default values keep the app functional (Strava features hidden) when
  // the file is absent, e.g. in CI or for contributors who don't need Strava.
  static const clientId     = String.fromEnvironment('STRAVA_CLIENT_ID',     defaultValue: '');
  static const clientSecret = String.fromEnvironment('STRAVA_CLIENT_SECRET', defaultValue: '');

  /// OAuth2 redirect URI – must match the appAuthRedirectScheme in
  /// build.gradle.kts and the callback domain on strava.com/settings/api.
  ///
  /// URI structure: scheme://host/path
  ///   scheme → appAuthRedirectScheme in build.gradle.kts  (= "apexpush")
  ///   host   → "Authorization Callback Domain" on strava.com/settings/api (= "apexpush")
  /// Both must match – Strava validates the host component, not the scheme.
  static const redirectUri = 'apexpush://apexpush/callback';
  static const scopes      = ['activity:write'];

  static const _authEndpoint  = 'https://www.strava.com/oauth/mobile/authorize';
  static const _tokenEndpoint = 'https://www.strava.com/oauth/token';
  static const apiBase        = 'https://www.strava.com/api/v3';

  static String get authorizationEndpoint => _authEndpoint;
  static String get tokenEndpoint         => _tokenEndpoint;

  /// True when actual credentials were provided at compile time.
  static bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;
}
