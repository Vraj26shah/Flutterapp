# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-10-19

### Added
- Splash with stored-session check; login with validation, password toggle and loading state.
- Secure token storage, automatic access-token refresh with retry, forced logout on 401/403.
- Product catalogue: responsive grid, infinite scroll, pull-to-refresh, category chips,
  debounced search, sort, shimmer skeletons and empty state.
- Product details: image carousel, hero animation, stock status, reviews, add to cart.
- Cart with Hive persistence, live badge, totals and simulated checkout via `POST /carts/add`.
- Profile from `GET /auth/me`, theme toggle (light/dark/system) and logout.
- Offline cache of the first catalogue page and categories with an offline banner.
- Adaptive navigation (bottom bar / rail) and master–detail on large screens.
- Error-handling playground for the brief's failure scenarios.
- 127 unit and widget tests (77% line coverage), GitHub Actions CI.
