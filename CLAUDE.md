# Casca App

Shared rules (contracts, cross-cutting security, dependencies, language, exploration, validation): `../CLAUDE.md`. Backend authorization, tenancy and auth: `../Casca/CLAUDE.md`. Reference implementation for conventions and behavior: `../casca-web/CLAUDE.md`.

Do not introduce comments in code (rule in `../CLAUDE.md`): this includes `///` doc comments unless the task asks for it.

## Stack

Flutter, Dart. Verify versions in `pubspec.yaml`; do not add, remove or upgrade dependencies without approval (see root). The app imports `package:material_ui/material_ui.dart` (as the project template does), not `material.dart`.

Installed: `flutter_svg` (SVG icons in `assets/icons/`, drawn only through `CascaIcon`/`CascaIcons`). The set is Phosphor Icons (MIT, license in `assets/icons/PHOSPHOR_LICENSE.txt`), copied as SVG, not as a package: each icon has an outline file `name.svg` and a filled one `name-fill.svg`. Use the outline by default and `CascaIcon(..., filled: true)` for active/selected states and brand marks; when adding an icon copy both variants. The Casca logo (the shopping bag) is the official mark and keeps the original Font Awesome Free SVG in `assets/brand/casca-bag.svg` (CC BY 4.0, keep the license comment inside) through `CascaIcons.brandBag`; never replace it with an icon-set equivalent and never use `filled` with it. Do not use icon fonts.

Installed: `mobile_scanner` (camera barcode reading, Android and iOS only, only through `CascaBarcodeCamera`; screens take it from `barcodeCameraProvider` so tests can fake it). Pressing Enter in the sales search adds the exact code (hardware scanners). To fill a barcode field use `cascaScanButton` (`shared/ui/casca_barcode_scanner.dart`, reads one code and closes) as the `action` of `CascaInput`; the product form and the variant modal use it.

Installed: `image_picker` (product photos, only through `PhotoPicker`; iOS usage descriptions live in `ios/Runner/Info.plist`).
Installed: `universal_ble` (BSD-3, Bluetooth LE on Android and iOS, only through `DevicePrinter` in `core/printing`; screens take it from `devicePrinterProvider` so tests can fake it).
Installed: `ffi` (calls `winspool.drv` for USB printing on Windows, only in `win32_print_spooler.dart`, imported conditionally so web still compiles).

Installed: `flutter_riverpod` (state), `go_router` (navigation), `dio` + `dio_cookie_manager` + `cookie_jar` (HTTP with cookie auth), `flutter_secure_storage` (encrypted cookie storage).

Planned (not installed yet, ask before adding): Drift (offline), Freezed + json_serializable (models; Dart models are hand-written for now).

Backend URL: `--dart-define=API_URL=https://...` (default `https://localhost:8080`; a physical phone cannot reach the PC's localhost, use a reachable HTTPS URL). Windows builds with plugins need Developer Mode enabled.

## Architecture

Feature-first. Mirrors `casca-web` (`core`, `features`, `shared`, theme) with Flutter names.

```
lib/
  main.dart
  app/ (app.dart, router/, theme/)
  core/ (config, errors, network, auth, layout, routing, database, storage, sync, permissions, utils)
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
- Keep token values in sync with web: change a token in both places or document the divergence. Known divergence: light `text` is `#334155` in the app (softer than black) and `#1e293b` in web.
- Font Poppins (400, 500, 600) is bundled in `assets/fonts/poppins/` (SIL OFL, keep `OFL.txt`); the fallback is Inter. Add a weight only if a token needs it.

## Design system

- Reuse `shared/ui` (`casca_*`) before creating new widgets. Do not use raw `ElevatedButton`, `TextField` or similar when a `casca_*` equivalent exists.
- `CascaQuantityStepper` is the quantity capsule (minus or trash, editable number, plus); `onChanged` returns the accepted quantity.
- If no component covers the need, or it must be extended, ask the user first.
- User-facing text in Spanish (see root).
- Available in `shared/ui`: `CascaButton`, `CascaInput` (text, password, `inputFormatters`, `maxLength`, `autofillHints`, `lines` for a textarea), `CascaSelect` (dropdown below the field; options take an `icon` SVG or an `image`), `CascaLink`, `CascaIcon`/`CascaIcons`, `CascaOverlayLoader` (full-screen loader, place it last inside a `Stack`), `CascaStepProgress`, `CascaPopover` (anchored panel with outside tap and Escape to close), `CascaActionMenu` (account-style menu built on it), `CascaTooltip` (hover tooltip, any side), `CascaCheckbox` (checked, unchecked or mixed with `null`), `CascaStatusChip` (tones success, warning, danger, info, neutral), `CascaTable<T>` (columns with `showOnCompact`: below 640 px only those plus checkbox and row-actions menu are drawn; optional selection with a floating bulk-actions bar, sort, pagination footer, skeleton, empty and error states; `CascaTableTwoLineCell` for title plus subtitle cells), `CascaPageHeader` (title, subtitle, optional action) and `CascaFilterBar` (search plus optional filter) for list screens, `CascaDeleteModal` (delete confirmation; the feature passes the loading and error state), `CascaCard`, `CascaSkeleton` (loading placeholders; use it instead of spinners when content is being fetched), `CascaSegmentedControl`, `CascaImageGrid` (main plus secondary images; on wide screens a mosaic with the main image on the left and `maxSecondary` slots in two rows, up to 768 px it becomes a swipeable carousel with a thumbnail strip, using `CascaImageItem.preview` for the large view), `CascaInput` `prefixText`/`suffixText`, `CascaModal` opened with `showCascaModal` (bottom sheet up to 768 px, centered dialog above; sizes sm, md, lg) and `showCascaConfirm` for yes/no questions. Input masks: `shared/formatters/MaskInputFormatter` (`phone`).
- Widgets of the same type in the same position reuse their `State`: when a screen swaps steps or views that contain stateful inputs, give each branch a distinct `key` (bug found in `RegisterPage`).

## State management

Riverpod: providers with lifecycle (`autoDispose`) per feature; no duplicated state between provider and widget; no global mutable singletons. No other state library without approval.

- One screen action = one `Notifier<AsyncValue<T>>` with `autoDispose` (`LoginController`, `RegisterController`, `ForgotPasswordController`, `SetPasswordController`). The page reads it with `ref.watch` in `build` and calls it with `ref.read(...notifier)` in handlers. After an `await` check `ref.mounted` before assigning `state` (the page may have been disposed by a redirect).
- Pages keep only UI state (current step, controllers); rules go in `features/<f>/domain`, texts of errors in the page.

## Routing and session

- `go_router` in `app/router/` (`app_router.dart`, `auth_redirect.dart`); path constants and `guestRoutes` in `core/routing/app_routes.dart` (features import from there, never from `app/`).
- Session lives in `core/auth/auth_controller.dart` (`AuthStatus` initializing/authenticated/unauthenticated, `signIn`, `register`, `signOut`, `restoreSession` via `/auth/me`, listens to `sessionExpiredProvider`). The router `redirect` follows it: never navigate by hand after login/logout.
- Registration creates tenant, store and user in one step, so a signed-in user always has a store (verified in `CreateAdminUserCommandHandler` and `MeCommandHandler`); there is no onboarding screen. `SessionState.activeStore` is non-null: a response without `store` fails to parse (a user stripped of stores loses access, not the record). The backend still sends `hasTenant` and `hasCompletedOnboarding`; the app ignores them on purpose.
- Product variants (create only, like web): options and generated combinations live in `productVariantsProvider`, rules in `domain/product_variant_rules.dart`. Existing products use `ProductVariantsManager` (rules in `domain/product_variant_view_rules.dart`): every action saves at once through `variantActionProvider`, which reloads the detail so the next action sends the new `version`; for that reason the edit form is keyed by product id, not by version. Variant sale units beyond the main one cannot be added (neither can web).
- Point of sale (`features/pos`, route `/pos`, grid only, no list view): rules in `domain/` (cart, payment, sale request and errors); money is compared in cents. The cart outlives the page and resets when the account, store or tax setting changes. Stores with taxes use `/sales/preview`; without taxes the total is local. Charging needs an open shift (the notice links to the current shift screen). Every sale sends `Idempotency-Key`, and an identical retry must reuse it. The payment modal mirrors the web one. Price lists for the whole sale or per line (`sale.applypricelist`) and custom price (`sale.customprice`); line precedence is custom price, line list, sale list, and the empty GUID forces the public price on a line. Any price list involved makes the server compute the total, even without taxes. A finished sale resets the sale list. The success modal prints the ticket. Not ported yet: customer, ticket email. Remote product pictures use `CascaRemoteImage` (`shared/ui`).
- Price lists (`features/price_lists`, `/price-lists`): list, create, rename, delete and per-product prices. An empty price means the public price (sent as `null`); only changed prices are saved, in batches of 500. The detail is a full-page form (hidden bottom bar, discard confirmation).
- Current shift (`/cash-register/current-shift`): open, deposit, withdrawal and a two-step close (`/current-shift/close`, full-page form), rules in `domain/close_shift_rules.dart`, same as web (expected amounts visible while counting). `currentShiftProvider` reloads after every action, failed ones included, because movements have no idempotency key and the user must see whether they were registered.
- Sales history (`features/sales`, `/sales` and detail): newest first, search by exact sale number, sortable headers; search, page and sort survive opening a sale and reset on account or store change. A sale opened from a shift detail carries `?turno=` so back returns to that shift. The detail reprints the ticket.
- Businesses (`features/businesses`, `/businesses`): stores grouped by business, switch store, create business (role Administrador) and answer invitations. Switching and creating apply the returned session with `AuthController.applySession` and go home; there is no app reload as in web, so any provider that outlives its page must watch the account or active store and reset. Not ported yet: pending invitations badge in the menu.
- Label printing: lives in `core/printing` instead of `features/peripherals` because products and settings both use it. The ZPL design is a port of `ProductLabelZplBuilder` in `casca-print-agent`; change both together. Printer and label size (default 51 x 25 mm) are stored per device. `/printers` (`features/printers`) picks, tests and sizes the label printer (tested target: Rongta RP425). Android and iOS use Bluetooth; Windows lists the installed printers on a USB port and sends the ZPL as a RAW job, refusing offline ones; products print from the list row action. Over Bluetooth, data is sent in paced chunks to a known printer characteristic and the connection is retried (Android error 133). The print modal previews the first label from the same layout as the ZPL (`product_label_layout.dart`); font is approximate and bars are illustrative, as in web. The product list selection (kept across pages) prints several products at once, variants included (web excludes them from the bulk selection).
- Sale tickets (`core/printing`): same content as `SaleTicketRenderer` in `casca-print-agent` (change both together), laid out in `sale_ticket_layout.dart`, drawn to a bitmap (58 mm = 384 dots, 80 mm = 576) and sent as ESC/POS raster through the same `DevicePrinter` as labels. The ticket printer has its own settings (tab "Tickets" in `/printers`). Create-sale and sale-detail responses share the shape parsed by `SaleTicket.tryParse`. The marketing QR is a fixed module matrix (`marketing_qr.dart`, generated with QRCoder, ECC M); regenerate it if the URL changes. Preferences per device: print automatically after a sale, and a second copy marked "DUPLICADO" (sale prints only; reprints are single and marked "REIMPRESIÓN"); web has neither. Print jobs are serialized by `PrintQueue`. The header draws the same bag logo as the agent (`ticket_logo.dart`). Not ported: store address/phone/RFC (web sends none).
- Shift history (`features/cash_registers`, `/cash-register/shift-history` and detail): read only, newest first, no filters yet (planned for a later phase). The detail pages movements and sales separately in one request. Server payment methods and movement types arrive as enum names and are translated in `domain/shift_rules.dart`. Dates go through `shared/formatters/date_formatters.dart` (local time).
- System back button: screens navigate with `context.go`, so there is no route stack. `AppShell` keeps the visited locations (`core/routing/navigation_history.dart`): back closes the drawer, then returns to the previous screen (never to a form already left), then home, and exits only from home. A page with its own `PopScope` takes precedence. Auth screens handle it through `AuthCardLayout.onBack` (only login exits).
- Full-page forms: add the path to `AppRoutes.isFormRoute`, set `onExit: confirmDiscard(ref)` on its route, register the dirty check in `unsavedChangesProvider` (`core/routing/unsaved_changes.dart`) and turn the system back button into "cancel" with `PopScope`.
- Android draws edge-to-edge: the shell adds the status/navigation bar insets itself (topbar grows by the top inset, bottom bar adds the bottom inset, drawer footer adds it too, page uses `SafeArea(top: false, bottom: false)`); auth screens use `SafeArea`; `app.dart` sets transparent system bars with icon brightness by theme. New full-screen pages outside the shell must use `SafeArea`.
- Navigation animations: shell pages use `shellPage` (fade + 1.5% slide up, 240 ms in / 160 ms out) instead of `NoTransitionPage`; the bottom bar tints icon and label (200 ms) and "pops" the newly active item; sidebar tiles tint their colors. Every animation must honor `MediaQuery.disableAnimationsOf` (reduce motion).
- Active navigation state is neutral, never blue: label and icon use `colors.text` over a `colors.text` 10% background (sidebar, flyout, preferences panel); the sidebar and flyout always draw the outline icon, only the mobile bottom bar switches to the filled variant when active; inactive is `textSecondary`. Blue stays for brand marks and links (the label of any active shortcut is semibold). Submenu items are 38 px high with 4 px gaps.
- The mobile topbar shows the brand (`BrandLockup`: logo + "Casca Tiendas", only "Casca" under 360 px) instead of a page title; the sidebar uses the same widget. There is no page-title in the topbar.
- Auth screens share `features/auth/presentation/widgets/auth_card_layout.dart`. Recovery flow: `forgot-password` -> `verify-reset-code` -> `change-password`.
- App shell in `core/layout/` mirrors web `core/layout`: `AppShell` (sidebar + topbar + content, breakpoint 768: below it the sidebar is a drawer (hamburger in the topbar or left-edge swipe) and a flat bottom bar (`MobileBottomBar`) shows up to 5 permitted shortcuts from `mobileTabModules`, with "Vender" always in the middle; all shortcuts look the same and only change color and icon variant when active. The bar is hidden on form routes (`AppRoutes.isFormRoute`), whose footer pads the system inset itself; the shell lifts the page above the keyboard), `Sidebar` (expanded 240 / compact 64 with flyout for groups), `Topbar` (44 px borderless menu button (collapses the sidebar on desktop, opens the drawer on mobile), 44 px notification bell, account menu with logout; on mobile also the current section title), `PreferencesNav` (desktop: side panel on preference routes; mobile: a back bar to `/preferences`, the full list in `PreferencesHubPage` which the sidebar footer opens on mobile). Modules, sections and permissions live in `navigation_items.dart` (same ids/routes/permissions as web `NavigationService`); visibility is computed in `navigation_provider.dart` from the session permissions (UI only, the backend authorizes). Authenticated routes go inside the `ShellRoute` in `app/router/app_router.dart`; every module without a real screen uses `ModulePlaceholderPage` until its feature exists: replace the placeholder route, do not add the route twice. Pages inside the shell must not use `Scaffold` (the shell provides `Material`). Direct URL access is not blocked by permission yet (web has `permission.guard`). Known divergence from web: `Productos` is a single entry to `/products` (no submenu), product categories live in preferences at `/categories`, and the inventory counts entry is removed from the main menu until its place is decided (its settings entry stays in preferences).

## API communication

- Single `ApiClient` in `core/network` that unwraps `ApiResponse<T>.data`; do not call Dio directly from features.
- Cookie auth with persistent cookie jar; refresh handled only by `auth_refresh_interceptor`. Changes to cookies, JWT or refresh need review in both repositories.
- Frontend (and app) permission checks are UX only; the backend authorizes.
- Contract changes: follow the cross-project procedure in `../CLAUDE.md`; Dart models are maintained manually.

## Offline

`core/database` + `core/sync` own persistence and the pending-operations queue. Design idempotency and retries before building offline sales. Do not assume offline works for a feature until it is implemented and tested.

## Testing

`flutter_test` (+ `mocktail` once approved). `test/` mirrors `lib/`. Prioritize `core/sync`, `domain/rules`, repositories and `shared/ui`. Inspect nearby tests first.

- Repositories: fake Dio adapter in `test/core/network/fake_http_adapter.dart`.
- Controllers and flows: override `authRepositoryProvider` with `test/support/fake_auth_repository.dart`; screen flows run through `routerProvider` in `test/app/router/app_router_test.dart`.
- Widget tests must wrap in `MaterialApp(theme: CascaTheme.light)` (`context.casca` needs the theme extension) and use a tall `tester.view.physicalSize` for long forms.

## Validation

Smallest scope: `flutter analyze` and `flutter test <path>`. Do not run builds for Android/iOS unless the task requires it. Report only what was actually executed.
