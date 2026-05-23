import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/workout.dart';
import 'strava_config.dart';

/// Result of a Strava activity export.
sealed class StravaResult {}

class StravaSuccess extends StravaResult {
  /// URL of the created activity on strava.com.
  final String activityUrl;
  StravaSuccess(this.activityUrl);
}

class StravaError extends StravaResult {
  final String message;
  StravaError(this.message);
}

class StravaCancelled extends StravaResult {}

/// Manages Strava OAuth2 authentication and activity export.
///
/// Tokens are stored in [FlutterSecureStorage] and refreshed automatically
/// before any API call if the access token has expired.
///
/// Usage:
///   await StravaService.instance.connect();          // OAuth2 flow
///   await StravaService.instance.isConnected;        // check login state
///   await StravaService.instance.exportActivity(...) // POST /v3/activities
///   await StravaService.instance.disconnect();       // clear tokens
class StravaService {
  StravaService._();
  static final instance = StravaService._();

  static const _keyAccessToken  = 'strava_access_token';
  static const _keyRefreshToken = 'strava_refresh_token';
  static const _keyExpiresAt    = 'strava_token_expires_at'; // Unix seconds

  final _appAuth  = const FlutterAppAuth();
  final _storage  = const FlutterSecureStorage();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Whether a valid (possibly expired-but-refreshable) token is stored.
  Future<bool> get isConnected async =>
      (await _storage.read(key: _keyAccessToken)) != null;

  /// Runs the OAuth2 authorization code flow (opens browser / Strava app).
  ///
  /// Returns true on success, false if the user cancelled or an error occurred.
  Future<bool> connect() async {
    if (!StravaConfig.isConfigured) return false;
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          StravaConfig.clientId,
          StravaConfig.redirectUri,
          clientSecret: StravaConfig.clientSecret,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: StravaConfig.authorizationEndpoint,
            tokenEndpoint:         StravaConfig.tokenEndpoint,
          ),
          scopes: StravaConfig.scopes,
        ),
      );
      await _storeTokens(result);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears all stored tokens (logout).
  Future<void> disconnect() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  /// Creates a manual Strava activity for [workout].
  ///
  /// [splits] contains per-set rep counts for structured training;
  /// empty for free training.
  /// [locale] controls the description language ('de' or 'en').
  Future<StravaResult> exportActivity({
    required Workout   workout,
    required List<int> splits,
    required String    locale,
  }) async {
    final token = await _validToken();
    if (token == null) return StravaError('not_connected');

    final name        = _activityName(workout, locale);
    final description = _description(workout, splits, locale);
    // Strava expects local datetime in ISO-8601 without ms (Z suffix optional).
    final startDate = _iso8601(workout.date);

    try {
      final response = await http.post(
        Uri.parse('${StravaConfig.apiBase}/activities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/x-www-form-urlencoded',
        },
        body: {
          'name':             name,
          'type':             'WeightTraining',
          'start_date_local': startDate,
          'elapsed_time':     '${workout.durationSeconds}',
          'description':      description,
        },
      );

      if (response.statusCode == 201) {
        final id = jsonDecode(response.body)['id'];
        return StravaSuccess('https://www.strava.com/activities/$id');
      }

      // 401 → token may have been revoked on Strava's side.
      if (response.statusCode == 401) {
        await disconnect();
        return StravaError('unauthorized');
      }

      return StravaError('http_${response.statusCode}');
    } catch (e) {
      return StravaError('network_error');
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  /// Returns a valid access token, refreshing if necessary.
  /// Returns null if not connected or refresh fails.
  Future<String?> _validToken() async {
    final accessToken  = await _storage.read(key: _keyAccessToken);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);

    if (accessToken == null) return null;

    // Refresh if token expires within the next 5 minutes.
    final expiresAt = int.tryParse(expiresAtStr ?? '') ?? 0;
    final nowSecs   = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (nowSecs < expiresAt - 300) {
      return accessToken; // still valid
    }

    return _refreshToken();
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) return null;
    if (!StravaConfig.isConfigured) return null;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          StravaConfig.clientId,
          StravaConfig.redirectUri,
          clientSecret: StravaConfig.clientSecret,
          refreshToken: refreshToken,
          grantType:    'refresh_token',
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: StravaConfig.authorizationEndpoint,
            tokenEndpoint:         StravaConfig.tokenEndpoint,
          ),
        ),
      );
      await _storeTokens(result);
      return result.accessToken;
    } catch (_) {
      // Refresh failed (e.g. user revoked access on Strava).
      await disconnect();
      return null;
    }
  }

  Future<void> _storeTokens(TokenResponse result) async {
    final expires = result.accessTokenExpirationDateTime
        ?.millisecondsSinceEpoch ?? 0;
    await _storage.write(key: _keyAccessToken,  value: result.accessToken);
    await _storage.write(key: _keyRefreshToken, value: result.refreshToken);
    await _storage.write(key: _keyExpiresAt,    value: '${expires ~/ 1000}');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _activityName(Workout workout, String locale) {
    if (workout.isFreeTraining) {
      return locale == 'de'
          ? 'Liegestütz-Training – Frei'
          : 'Push-Up Training – Free';
    }
    final level = workout.levelId ?? '';
    final diff  = workout.difficulty ?? '';
    return locale == 'de'
        ? 'Liegestütz-Training – $level $diff'
        : 'Push-Up Training – $level $diff';
  }

  String _description(Workout workout, List<int> splits, String locale) {
    final total = workout.count;
    if (locale == 'de') {
      if (workout.isFreeTraining || splits.isEmpty) {
        return 'Freies Training\n$total Wiederholungen';
      }
      return 'Sätze: ${splits.join(' · ')}\nGesamt: $total Wdh.';
    } else {
      if (workout.isFreeTraining || splits.isEmpty) {
        return 'Free Training\n$total reps';
      }
      return 'Sets: ${splits.join(' · ')}\nTotal: $total reps';
    }
  }

  /// Formats [dt] as ISO 8601 without milliseconds, e.g. "2026-05-23T18:30:00".
  static String _iso8601(DateTime dt) {
    final y  = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:$s';
  }
}
