import 'dart:async';

import 'package:app/shared/utils/env.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await Env.load(environment: const String.fromEnvironment('APP_ENV', defaultValue: 'test'));
  return testMain();
}
