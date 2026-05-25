import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
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
/// Uses [FlutterWebAuth2] for the authorization code flow — this avoids the
/// AppAuth-Android task-affinity issue where [AuthorizationManagementActivity]
/// gets killed while Chrome is open, causing the callback to be lost.
///
/// Token exchange and refresh are done via plain HTTP POSTs.
/// Tokens are stored in [FlutterSecureStorage].
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

  final _storage = const FlutterSecureStorage();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Whether a valid (possibly expired-but-refreshable) token is stored.
  Future<bool> get isConnected async =>
      (await _storage.read(key: _keyAccessToken)) != null;

  /// Runs the OAuth2 authorization code flow (opens browser).
  ///
  /// Returns null on success, or an error string on failure.
  /// Returns 'cancelled' if the user closed the browser.
  Future<String?> connect() async {
    if (!StravaConfig.isConfigured) {
      debugPrint('[Strava] connect() aborted: isConfigured=false '
          '(run with --dart-define-from-file=strava.env.json)');
      return 'not_configured';
    }

    final state  = _generateState();
    final authUri = Uri.parse(StravaConfig.authorizationEndpoint).replace(
      queryParameters: {
        'client_id':     StravaConfig.clientId,
        'redirect_uri':  StravaConfig.redirectUri,
        'response_type': 'code',
        'scope':         StravaConfig.scopes.join(','),
        'state':         state,
      },
    );

    debugPrint('[Strava] starting OAuth2 — clientId=${StravaConfig.clientId}, '
        'redirectUri=${StravaConfig.redirectUri}');

    try {
      final resultUri = await FlutterWebAuth2.authenticate(
        url:               authUri.toString(),
        callbackUrlScheme: 'apexpush',
      );

      final params = Uri.parse(resultUri).queryParameters;

      if (params['state'] != state) {
        debugPrint('[Strava] state mismatch — possible CSRF');
        return 'state_mismatch';
      }

      final error = params['error'];
      if (error != null) {
        debugPrint('[Strava] auth error from Strava: $error');
        return error;
      }

      final code = params['code'];
      if (code == null) {
        debugPrint('[Strava] no code in callback: $resultUri');
        return 'no_code';
      }

      return await _exchangeCode(code);
    } catch (e, st) {
      debugPrint('[Strava] connect() error: $e');
      debugPrintStack(stackTrace: st, label: '[Strava]');
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('dismiss') || msg.contains('closed') ||
          msg.contains('UserCancelled')) {
        return 'cancelled';
      }
      return msg;
    }
  }

  /// Clears all stored tokens (logout).
  Future<void> disconnect() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  /// Creates a manual Strava activity for [workout].
  Future<StravaResult> exportActivity({
    required Workout   workout,
    required List<int> splits,
    required String    locale,
  }) async {
    final token = await _validToken();
    if (token == null) return StravaError('not_connected');

    final name        = _activityName(workout, locale);
    final description = _description(workout, splits, locale);
    final startDate   = _iso8601(workout.date);

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

  Future<String?> _validToken() async {
    final accessToken  = await _storage.read(key: _keyAccessToken);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);

    if (accessToken == null) return null;

    final expiresAt = int.tryParse(expiresAtStr ?? '') ?? 0;
    final nowSecs   = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (nowSecs < expiresAt - 300) return accessToken; // still valid

    return _refreshToken();
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) return null;
    if (!StravaConfig.isConfigured) return null;

    try {
      final response = await http.post(
        Uri.parse(StravaConfig.tokenEndpoint),
        body: {
          'client_id':     StravaConfig.clientId,
          'client_secret': StravaConfig.clientSecret,
          'refresh_token': refreshToken,
          'grant_type':    'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[Strava] token refresh failed: ${response.statusCode}');
        await disconnect();
        return null;
      }

      final json        = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String;
      await _storeTokens(
        accessToken:  accessToken,
        refreshToken: json['refresh_token'] as String,
        expiresAt:    json['expires_at'] as int,
      );
      return accessToken;
    } catch (e) {
      debugPrint('[Strava] token refresh error: $e');
      await disconnect();
      return null;
    }
  }

  /// Exchanges an authorization code for access + refresh tokens.
  Future<String?> _exchangeCode(String code) async {
    debugPrint('[Strava] exchanging auth code for tokens');
    try {
      final response = await http.post(
        Uri.parse(StravaConfig.tokenEndpoint),
        body: {
          'client_id':     StravaConfig.clientId,
          'client_secret': StravaConfig.clientSecret,
          'code':          code,
          'grant_type':    'authorization_code',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[Strava] token exchange failed: '
            '${response.statusCode} ${response.body}');
        return 'token_exchange_${response.statusCode}';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await _storeTokens(
        accessToken:  json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresAt:    json['expires_at'] as int,
      );
      debugPrint('[Strava] connect() success');
      return null; // success
    } catch (e) {
      debugPrint('[Strava] token exchange error: $e');
      return e.toString();
    }
  }

  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required int    expiresAt,   // Unix seconds
  }) async {
    await _storage.write(key: _keyAccessToken,  value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyExpiresAt,    value: '$expiresAt');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Generates a random state string for CSRF protection.
  String _generateState() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _activityName(Workout workout, String locale) {
    if (workout.isFreeTraining) {
      return locale == 'de'
          ? '💪 Liegestütz-Training – Frei'
          : '💪 Push-Up Training – Free';
    }
    final level = workout.levelId ?? '';
    final diff  = workout.difficulty ?? '';
    return locale == 'de'
        ? '💪 Liegestütz-Training – $level $diff'
        : '💪 Push-Up Training – $level $diff';
  }

  String _description(Workout workout, List<int> splits, String locale) {
    final total    = workout.count;
    final mins     = workout.durationSeconds ~/ 60;
    final secs     = workout.durationSeconds % 60;
    final dur      = mins > 0
        ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
        : '${secs}s';
    final calories = (total * 0.5).round();
    final sep      = '─────────────────────';

    if (locale == 'de') {
      final buf = StringBuffer();
      buf.writeln(sep);
      if (!workout.isFreeTraining) {
        final level = workout.levelId ?? '';
        final diff  = workout.difficulty ?? '';
        buf.writeln('🎯 Level $level · $diff');
        buf.writeln();
      }
      if (splits.isNotEmpty) {
        buf.writeln('📊 Sätze:  ${splits.join(' · ')}');
      }
      buf.writeln('🔢 Gesamt: $total Wdh.');
      buf.writeln('⏱️ Dauer:  $dur');
      buf.writeln('🔥 Kalorien: ~$calories kcal');
      buf.writeln(sep);
      buf.write('📱 ApexPush');
      return buf.toString();
    } else {
      final buf = StringBuffer();
      buf.writeln(sep);
      if (!workout.isFreeTraining) {
        final level = workout.levelId ?? '';
        final diff  = workout.difficulty ?? '';
        buf.writeln('🎯 Level $level · $diff');
        buf.writeln();
      }
      if (splits.isNotEmpty) {
        buf.writeln('📊 Sets:      ${splits.join(' · ')}');
      }
      buf.writeln('🔢 Total:     $total reps');
      buf.writeln('⏱️ Duration:  $dur');
      buf.writeln('🔥 Calories:  ~$calories kcal');
      buf.writeln(sep);
      buf.write('📱 ApexPush');
      return buf.toString();
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
