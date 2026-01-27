# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2026-01-27

### Added
- Domain selection in the mix task via `--domain` (including `errors.po`).
- HTML auto-detection and placeholder protection for safer translations.
- PO translation pipeline using Expo with plural support and metadata preservation.
- Configurable translation options (`format`, `model`) and injectable translator for tests.
- Tests for the mix task and Google translator, plus higher overall coverage.

### Changed
- Updated for modern Gettext/Phoenix compatibility and `Gettext.Backend` usage.
- Switched to Goth token fetching API and improved translator options handling.
- README now includes a clearer quick start, domains, updates, troubleshooting, and examples.

