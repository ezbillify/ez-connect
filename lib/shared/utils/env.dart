import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static const String _supabaseUrlOverride =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonKeyOverride =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _supabaseFunctionUrlOverride =
      String.fromEnvironment('SUPABASE_FUNCTION_URL', defaultValue: '');
  static const String _appEnvOverride =
      String.fromEnvironment('APP_ENV', defaultValue: '');

  static bool _isLoaded = false;
  static String? _loadedFile;
  static String _activeEnvironment =
      _appEnvOverride.isNotEmpty ? _appEnvOverride : 'development';

  static Future<void> load({String? environment, bool force = false}) async {
    if (_isLoaded && !force) {
      return;
    }

    final targetEnvironment = environment ??
        (_appEnvOverride.isNotEmpty ? _appEnvOverride : 'development');

    final candidateFiles = <String>[
      '.env.local',
      'config/environments/.env.$targetEnvironment',
      '.env.$targetEnvironment',
      '.env',
      'config/environments/.env.development',
    ];

    for (final fileName in candidateFiles) {
      try {
        await dotenv.load(
          fileName: fileName,
          mergeWith: {
            'APP_ENVIRONMENT': targetEnvironment,
          },
        );
        _isLoaded = true;
        _loadedFile = fileName;
        _activeEnvironment = dotenv.env['APP_ENVIRONMENT'] ?? targetEnvironment;
        return;
      } catch (_) {
        // ignore and continue to the next candidate
      }
    }

    dotenv.testLoad(
      fileInput: '''
APP_ENVIRONMENT=$targetEnvironment
''',
    );

    _isLoaded = true;
    _loadedFile = null;
    _activeEnvironment = targetEnvironment;
  }

  static bool get isLoaded => _isLoaded;

  static String get environment => _activeEnvironment;

  static String? get loadedFile => _loadedFile;

  static String? get supabaseUrl {
    if (_supabaseUrlOverride.isNotEmpty) {
      return _supabaseUrlOverride;
    }
    final value = dotenv.env['SUPABASE_URL'];
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static String? get supabaseAnonKey {
    if (_supabaseAnonKeyOverride.isNotEmpty) {
      return _supabaseAnonKeyOverride;
    }
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static String? get supabaseFunctionUrl {
    if (_supabaseFunctionUrlOverride.isNotEmpty) {
      return _supabaseFunctionUrlOverride;
    }
    final value = dotenv.env['SUPABASE_FUNCTION_URL'];
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static String get appEnvironment => environment;
}
