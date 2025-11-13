# Environment Configuration

The application supports dedicated configuration per environment (development, staging, test, production) using `.env` files stored under `config/environments/`.

## File Layout

```
config/
└── environments/
    ├── .env.development
    ├── .env.staging
    ├── .env.test
    └── .env.production
```

Each file contains the variables used to initialise Supabase:

```bash
APP_ENVIRONMENT=development
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=local-anon-key
SUPABASE_FUNCTION_URL=http://localhost:54321/functions/v1
```

The files committed to the repository include placeholders. For sensitive values, create copies suffixed with `.local`, which are ignored by git:

```bash
cp config/environments/.env.production config/environments/.env.production.local
# edit the *.local file with real credentials
```

Update your shell or CI system to export `APP_ENV=production` so the correct file is used at runtime.

## Runtime Selection

`Env.load()` in `lib/shared/utils/env.dart` determines which configuration to load:

1. `APP_ENV` defined via `--dart-define=APP_ENV=<env>` or environment variable.
2. `APP_ENVIRONMENT` within the resolved `.env` file.
3. Defaults to `development` if nothing else is provided.

The loader attempts to read files in the following order until one is found:

1. `config/environments/.env.<env>`
2. `.env.<env>`
3. `.env`
4. `config/environments/.env.development`

The selected file is bundled as a Flutter asset (see `pubspec.yaml`).

## Local Development

- Default environment: `development`.
- Run the app with `flutter run -d chrome` (loads `.env.development`).
- To target another environment locally: `APP_ENV=staging flutter run -d chrome`.

## Testing

- Automated tests use `APP_ENV=test`.
- `scripts/run_flutter_tests.sh` exports `APP_ENV=test` and can start Supabase locally before executing tests.

## CI / CD

- GitHub Actions sets `APP_ENV=test` for unit/widget/integration tests.
- Use repository secrets for production/staging values when invoking the build scripts.

## Passing Overrides Without Files

You can bypass the `.env` files by providing dart-defines at build time:

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=SUPABASE_URL=https://staging-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=staging-anon-key
```

These overrides take precedence over values in the env files, enabling secure CI/CD pipelines without committing secrets.

## Troubleshooting

- **Missing credentials warning**: If the app logs `Supabase credentials were not provided`, ensure the target `.env` file exists and contains non-empty values or pass dart-defines explicitly.
- **Asset not found errors**: Run `flutter pub get` after adding new env files to regenerate the asset bundle.
- **CI build uses wrong environment**: Double-check `APP_ENV` exported in the workflow and that the corresponding `.env.<env>` file is available.
