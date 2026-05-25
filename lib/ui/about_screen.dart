import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

// Replace with your actual donation URL.
const _donationUrl = 'https://ko-fi.com';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
  }

  Future<void> _openDonation() async {
    final uri = Uri.parse(_donationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final hintColor = scheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('about'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── App identity ────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/icon.png',
                    width:  80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ApexPush',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${context.t('version')} $_version',
                    style: TextStyle(color: hintColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Impressum ───────────────────────────────────────────────────────
          Text(
            context.t('impressum'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(context.t('impressum_text'), style: TextStyle(color: hintColor)),
          const SizedBox(height: 32),

          // ── Donation ────────────────────────────────────────────────────────
          Text(
            context.t('support_the_app'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(context.t('donation_text'), style: TextStyle(color: hintColor)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style:     OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon:      const Icon(Icons.favorite_outline),
            label:     Text(context.t('donate')),
            onPressed: _openDonation,
          ),
        ],
      ),
    );
  }
}
