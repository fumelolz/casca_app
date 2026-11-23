# Casca App

Shared rules (contracts, cross-cutting security, dependencies, language, exploration, validation): `../CLAUDE.md`. Backend authorization, tenancy and auth: `../Casca/CLAUDE.md`. Reference implementation for conventions and behavior: `../casca-web/CLAUDE.md`.

Do not introduce comments in code (rule in `../CLAUDE.md`): this includes `///` doc comments unless the task asks for it.

## Stack

Flutter, Dart. Verify versions in `pubspec.yaml`; do not add, remove or upgrade dependencies without approval (see root). The app imports `package:material_ui/material_ui.dart` (as the project template does), not `material.dart`.

Installed: `flutter_svg` (SVG icons in `assets/icons/`, drawn only through `CascaIcon`/`CascaIcons`, copied from the Font Awesome Free set used by casca-web; keep the license comment inside each SVG, CC BY 4.0). Do not use icon fonts.

Installed: `flutter_riverpod` (state), `go_router` (navigation), `dio` + `dio_cookie_manager` + `cookie_jar` (HTTP with cookie auth), `flutter_secure_storage` (encrypted cookie storage).

Planned (not installed yet, ask before adding): Drift (offline), Freezed + json_serializable (models; Dart models are hand-written for now).

Backend URL: `--dart-define=API_URL=https://...` (default `https://localhost:8080`; a physical phone cannot reach the PC's localhost, use a reachable HTTPS URL). Windows builds with plugins need Developer Mode enabled.

## Architecture

Feature-first. Mirrors `casca-web` (`core`, `features`, `shared`, theme) with Flutter names.

```
lib/
  main.dart
  app/ (app.dart, router/, theme/)
  core/ (config, errors, network, auth, database, storage, sync, permissions, utils)
  shared/ (ui, widgets, extensions, formatters)
  features/<feature>/ (data, domain, presentation)
test/ (mirrors lib/)
```

Create only the layers a feature needs:

- Remote-only feature (`reports`, `dashboard`): `data/models`, `data/<feature>_repository.dart`, `presentation`.
- Feature with sync (`products`, `customers`, `inventory`): add `data/datasources` (remote and local); concrete repository, no interface by default.
- Feature with real business rules or offline queue (`sales`, `cash_register`): add `domain` (`entities`, `rules`, `usecases`, repository interface).
- Platform feature (`peripherals`): interfaces in `domain`, implementations per platform in `data`.

Do not create a use case that only forwards to a repository. Do not split entity/model until API and domain diverge.

Flow: Pages/Widgets -> Providers (notifiers) -> Repositories -> Datasources -> `core/network` | `core/database`.

Dependency rules:

- `features/*` may use `core/` and `shared/`. `core/` and `shared/` never import from `features/`.
- A feature never imports another feature; move shared code to `core/` or `shared/`.
- `app/` is the only layer that knows every feature (router).

Equivalence with casca-web: facade = provider/notifier, `ApiClient` = `core/network/api_client.dart`, `authGuard` = router `redirect`, Dexie = Drift, `shared/ui` = `shared/ui`.

## Naming

Files `snake_case`; classes `PascalCase`. Suffixes: `_page`, `_provider`, `_repository`, `_datasource`, `_model`, `_rules`, `_test`. Design-system widgets use the `casca_` prefix (`casca_button.dart`, class `CascaButton`).

## Theme

Source of truth: `lib/app/theme/`, ported from `casca-web/src/styles/tokens`.

- Colors: `CascaColors` (`ThemeExtension`, light and dark). Read them with `context.casca`; never hardcode `Color(0x...)` or `Colors.*` in widgets.
- Spacing, radius, shadows, typography: `CascaSpacing`, `CascaRadius`, `CascaShadows`, `CascaFontSize`/`CascaFontWeight`. No magic numbers for padding, radius or font size.
- Keep token values in sync with web: change a token in both places or document the divergence.
- Font Poppins (400, 500, 600) is bundled in `assets/fonts/poppins/` (SIL OFL, keep `OFL.txt`); the fallback is Inter. Add a weight only if a token needs it.

## Design system

- Reuse `shared/ui` (`casca_*`) before creating new widgets. Do not use raw `ElevatedButton`, `TextField` or similar when a `casca_*` equivalent exists.
- If no component covers the need, or it must be extended, ask the user first.
- User-facing text in Spanish (see root).

## State management

Riverpod once approved: providers with lifecycle (`autoDispose`) per feature; no duplicated state between provider and widget; no global mutable singletons. No other state library without approval.

## API communication

- Single `ApiClient` in `core/network` that unwraps `ApiResponse<T>.data`; do not call Dio directly from features.
- Cookie auth with persistent cookie jar; refresh handled only by `auth_refresh_interceptor`. Changes to cookies, JWT or refresh need review in both repositories.
- Frontend (and app) permission checks are UX only; the backend authorizes.
- Contract changes: follow the cross-project procedure in `../CLAUDE.md`; Dart models are maintained manually.

## Offline

`core/database` + `core/sync` own persistence and the pending-operations queue. Design idempotency and retries before building offline sales. Do not assume offline works for a feature until it is implemented and tested.

## Testing

`flutter_test` (+ `mocktail` once approved). `test/` mirrors `lib/`. Prioritize `core/sync`, `domain/rules`, repositories and `shared/ui`. Inspect nearby tests first.

## Validation

Smallest scope: `flutter analyze` and `flutter test <path>`. Do not run builds for Android/iOS unless the task requires it. Report only what was actually executed.
