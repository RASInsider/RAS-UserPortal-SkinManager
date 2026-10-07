# Changelog

## Unreleased — 0.1.1-dev

- Synchronize the user's standalone Desktop PS1, including the previously added RAS 21.2.x version gate. Gateway API strings such as `21.2 (build 27429)` are accepted. RAS 22.0 TP remains restricted to build 28102 unless explicitly overridden.
- Add seven embedded presets: Graphite, Forest, Warm Ivory, Bordeaux, Aubergine, Liquid Glass and Ruby. Total: 11 built-in themes plus Custom.
- Extend `-Preset` validation and the interactive menu. Preserve existing choices 1–5, including Custom at 5; new choices are 6–12.
- Add light text on dark corporate palettes and dark text on Warm Ivory. Corporate palettes use 0.96 panel/header opacity. Original presets retain their prior configuration.
- Add Liquid Glass: translucent pale panels, 36px blur, 30px radius, white inset highlights and rounded search inputs. This is a CSS-only community interpretation, with no Apple assets or native refraction.
- Name the red graphite/ruby theme **Ruby**; no vendor name is used in its preset identifier.
- Document exact palettes, opacity, CLI/menu usage, compatibility limits and the difference between the development source and the unchanged v0.1.0 release.
- Expand local fixtures and Pester coverage for every theme, original-preset stability and Liquid Glass-specific CSS isolation. Include optional JSON examples for the seven new presets.

The deployed assets, RASAdmin discovery, WinRM authentication, transaction/rollback, current-index restore and branding ownership architecture are unchanged by the theme additions. The Desktop script retains explicit Negotiate remoting authentication; this update does not import an unrelated experimental authentication change. No live deployment or new release is performed by this source update.

## v0.1.0 — 2026-10-07 (preview)

- Standalone PowerShell manager with Install/Change, Re-apply, Restore, Status and Exit.
- Five embedded presets and structured Custom skin validation; independent CSS using `--ri-*` variables.
- Documentation-backed RASAdmin discovery with installed contract checks, multiple Site/Gateway scopes and authenticated WinRM transport.
- All-target pre-flight, all-target preparation, snapshot/hash verification, transaction journal and compensating rollback/recovery.
- Marker-based idempotent hook, current-index surgical restore, upgrade hook repair and deliberate prototype adoption/drift reconciliation.
- English documentation, MIT license, JSON examples and local/fixture regression tests.

Recorded prototype baseline: Parallels RAS 22.0 Technical Preview build 28102. Live deployment/API integration, Theme-change and Windows ACL validation are pending. See docs/VALIDATION.md for actual evidence. Independent, unsupported community project.
