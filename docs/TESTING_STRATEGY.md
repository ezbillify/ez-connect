# Flutter Testing Strategy

This document outlines the testing approach for the CRM Flutter application. It covers the testing pyramid, tooling, environment configuration, and how to run the different suites locally and in CI.

## Testing Pyramid

```
                End-to-end (Integration)
                   ───────────────────
                      Widget Tests
                   ───────────────────
                         Unit Tests
```

- **Unit tests** validate individual classes and pure Dart logic.
- **Widget tests** exercise presentation logic and widget composition using Flutter's widget testing APIs.
- **Integration tests** validate cross-cutting flows such as realtime event handling and Supabase interactions (using local services where possible).

## Test Suites

### Unit Tests
- Located under `test/models/`, `test/repositories/`, and `test/features/`.
- Focus on domain models, repository interfaces, and utility classes.
- Use the `mockito` package for mocking dependencies where external services are involved.

Run only unit tests:
```bash
flutter test test/models test/repositories test/features
```

### Widget Tests
- Located under `test/widget_tests/`.
- Verify layout, navigation, and interaction logic without depending on real backend services.
- Use `WidgetTester` with mock providers and fixtures to keep tests deterministic.

Run widget tests:
```bash
flutter test test/widget_tests
```

### Integration Tests
- Located under `test/integration/` and `test/features/.../integration`.
- Cover realtime event flows and repository behaviours that orchestrate multiple components.
- For backend-aware scenarios, start a local Supabase stack (Docker) and run migrations before executing the tests.

Run integration tests with local Supabase:
```bash
# Ensure Supabase CLI and Docker are installed
npm install -g supabase

# Bootstrap the local stack and run the full suite with coverage
./scripts/run_flutter_tests.sh
```

This helper script will:
1. Start/refresh the local Supabase containers.
2. Apply database migrations and seed data (via `supabase db reset`).
3. Execute `flutter test --coverage` with `APP_ENV=test` so the app uses `config/environments/.env.test`.
4. Stop Supabase services when the run finishes.

## Coverage Tooling

Code coverage is generated via the standard Flutter tooling:

```bash
flutter test --coverage
```

The resulting `coverage/lcov.info` file can be opened with tools such as VSCode's **Coverage Gutters** extension or uploaded to third-party dashboards. The CI pipeline stores it as an artifact for review.

To generate an HTML report locally:
```bash
# Requires lcov to be installed (on macOS: brew install lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Environment Configuration for Tests

All automated test runs use the `config/environments/.env.test` file. Update this file with local Supabase credentials if you need to exercise authenticated flows. The CI pipeline injects the same configuration and starts Supabase automatically before executing the tests.

- `APP_ENV=test` ensures the runtime loads the appropriate env file (wired up via `test/flutter_test_config.dart`).
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` default to the local emulator ports.

## Continuous Integration

The GitHub Actions workflow performs the following checks on every push and pull request:

1. `dart format --set-exit-if-changed` – ensures formatting consistency.
2. `flutter analyze` – static analysis and linting.
3. `flutter test --coverage` – runs the complete test suite while a local Supabase stack is active.
4. Publishes the coverage report as an artifact.

Failures in any step will block the merge until issues are resolved.

## Troubleshooting

- **Supabase containers fail to start**: ensure Docker is running and stop lingering containers with `supabase stop` or `docker ps` / `docker stop`.
- **Missing environment variables**: double-check the `.env.*` files inside `config/environments/`. Use `APP_ENV=<env> flutter run` to load a specific configuration.
- **Coverage directory not created**: verify that tests are finishing successfully. Partial runs that exit early may skip coverage generation.

For additional guidance, consult `docs/SUPABASE_MIGRATIONS.md` and the README sections on testing and CI.
