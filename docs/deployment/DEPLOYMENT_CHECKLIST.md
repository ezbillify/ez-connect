# Deployment Checklist

This checklist guides you through everything required to promote a release across environments (development ➜ staging ➜ production). Use it before every deployment to ensure infrastructure, configuration, and application artifacts are ready.

## 1. Supabase Preparation

- [ ] **Create / select project** in the Supabase dashboard for the target environment.
- [ ] **Configure environment variables** (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, storage buckets, OAuth providers) in Supabase **and** in the Flutter build pipeline.
- [ ] **Review `supabase/config.toml`** to confirm local ports and project ID align with the target project.
- [ ] **Update storage buckets**: create required buckets (e.g., `ticket-attachments`) and configure public/private access policies.
- [ ] **Auth providers**: ensure email templates, redirect URLs, and external OAuth providers are configured for the environment domain.

## 2. Database Schema & Seed Data

- [ ] Pull latest changes: `git pull origin main`.
- [ ] Apply migrations locally to validate: `./supabase_dev.sh migrate`.
- [ ] Run automated tests: `./scripts/run_flutter_tests.sh`.
- [ ] Link Supabase project: `supabase link --project-ref <project-ref>`.
- [ ] Deploy migrations: `supabase db push`.
- [ ] (Optional) Re-run seeds if necessary using `supabase db reset` on non-production environments.
- [ ] Verify schema state: `supabase migration list`.

## 3. Flutter Environment Configuration

- [ ] Update `config/environments/.env.<env>` with accurate Supabase keys/URLs.
- [ ] For secrets, create `config/environments/.env.<env>.local` (ignored by git) and reference it in your CI/CD system.
- [ ] Validate environment loading via: `APP_ENV=<env> flutter run -d chrome`.
- [ ] Confirm Supabase initialization succeeds (no warnings in logs).

## 4. Build Artifacts

### Web
- [ ] Run `./scripts/build_web.sh` (defaults to `APP_ENV=production`).
- [ ] Upload `build/web/` directory to hosting provider (e.g., Vercel, Netlify, Firebase Hosting).
- [ ] Configure rewrite rules for SPA routing (serve `index.html` for unknown paths).

### Android
- [ ] Ensure `android/key.properties` and keystore exist (copy the `.example` template).
- [ ] Run `./scripts/build_android.sh appbundle` for Play Store or `apk` for direct distribution.
- [ ] Sign the artifact or confirm Gradle signing config points to release keystore.
- [ ] Upload `.aab` to Google Play Console and complete release notes/testing tracks.

### iOS
- [ ] On macOS, open `ios/Runner.xcworkspace` and ensure the bundle identifier & signing team match the target environment.
- [ ] Update provisioning profiles and certificates as required.
- [ ] Run `./scripts/build_ios.sh --no-codesign` for local smoke tests or remove the flag when codesigning for TestFlight/App Store.
- [ ] Validate the generated `.ipa` inside `build/ios/ipa/` and upload via Transporter or Xcode Organizer.

## 5. Post-deployment Verification

- [ ] Smoke test authentication flows (email login + magic link if enabled).
- [ ] Verify realtime updates (products, customers, tickets) propagate across clients.
- [ ] Confirm integration tokens function (create token, hit /tickets endpoint).
- [ ] Check storage uploads/downloads with the new bucket configuration.
- [ ] Monitor Supabase logs and dashboard metrics for anomalies.

## 6. Rollback Plan

- [ ] Keep the previous Flutter build artifacts accessible.
- [ ] Ensure database backups (Supabase automatic backups or manual `pg_dump`) are available.
- [ ] Document steps to revert to previous Supabase schema (`supabase migration revert`).

## References

- [Supabase Migrations Guide](../SUPABASE_MIGRATIONS.md)
- [External Integrations Guide](../EXTERNAL_INTEGRATIONS.md)
- [Testing Strategy](../TESTING_STRATEGY.md)
- [Environment Configuration](../ENVIRONMENT_CONFIGURATION.md)

Keep this checklist up to date as the deployment pipeline evolves.
