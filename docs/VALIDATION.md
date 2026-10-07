# Validation evidence — v0.1.0 preview

## Current development update — theme expansion, 2026-10-07

The sections below retain the historical v0.1.0 evidence. The development PS1 is now **0.1.1-dev**, synchronized byte-for-byte from the user's Desktop working file. It additionally allows RAS 21.2.x and embeds seven new themes, for 11 built-in presets plus Custom. This source update does not alter the v0.1.0 tag/archive.

Checks executed on macOS with PowerShell 7.6.6 against the updated source:

- Parser and filesystem fixture suite: **52/52 passed**.
- Pester 6.2.0: **17/17 passed**.
- PSScriptAnalyzer 1.25.0: no Error/Warning diagnostics with repository settings, including Windows PowerShell 5.1 syntax compatibility.
- All 12 preset/configuration choices generate validated CSS. Optional new JSON examples generate the same CSS as embedded definitions.
- Original Dark Glass/Midnight Blue/Light Glass/RASInsider definitions match their existing JSON examples. Custom still starts from Dark Glass; existing menu choices 1–5 are preserved.
- Liquid Glass highlights are isolated from ordinary themes. No asset URL is introduced into generated stylesheets.
- Existing local transaction, surgical restore, encoding, drift and mocked multi-Gateway rollback fixtures passed.

No Windows/RAS target was contacted by these checks. The seven new themes were reviewed in illustrative previews, not validated as live portal screenshots. Real-wallpaper contrast, Theme-change survival, disabled/error/focus states, browser fallback and multi-Gateway/HALB rendering remain lab checks. The Desktop working file retains forced Negotiate authentication; the separate previously exercised Kerberos/default-authentication experimental copy is not substituted here. The RAS 21.2.x gate is an allowed-version rule, not proof that every 21.2 build or this exact file was tested remotely.

See [THEMES.md](THEMES.md) for exact colors, numbers, usage and limitations.

Date: 2026-10-07. This separates the user's recorded prototype, read-only browser inspection and newly executed release checks. No live Windows deployment is claimed.

## Executed locally

Environment: macOS, PowerShell **7.6.6**. The script targets Windows PowerShell **5.1** for live RASAdmin administration; syntax compatibility with 5.1 was checked statically, not by running that Windows host here.

| Check | Result |
| --- | --- |
| PowerShell parser, main PS1 | Passed |
| `tests/Run-Checks.ps1` | **34 / 34 passed** |
| Pester **6.2.0**, `tests/Manager.Tests.ps1` | **14 / 14 passed** |
| PSScriptAnalyzer **1.25.0**, repository settings | No Error/Warning diagnostics |
| PSUseCompatibleSyntax, target 5.1 | Passed |

PSScriptAnalyzer exclusions are limited to intentional console menu output and the unused-parameter rule, which cannot follow script parameters consumed by the main function's inherited scope/serialized worker helpers. No security or parser rules are disabled.

The filesystem checks cover all embedded presets; CSS injection, finite/range/type/schema validation; locale-invariant rendering; marker uniqueness; byte-idempotence; UTF-8/UTF-16 BOM/newline handling; preservation of upgraded current-index content; unmarked prototype refusal; path traversal; read-only status; prepare/commit/verify/finalize; repeated install/re-apply/restore; crash rollback; and concurrent-edit refusal.

Pester includes actual local filesystem workers with **mocked transport** representing **two Gateways in two Sites**. It verifies all-target pre-flight failure with no Prepare/Commit, all-target staging before the first live fixture commit, all-target verification, rollback after the second target fails, honest partial rollback/recovery journals, drift before preparation and reviewed prototype adoption. These are simulations, not Windows/RAS Farm tests. The serialized remote worker is parsed as well.

## Executed GitHub Windows checks

[Windows CI run 37590811033](https://github.com/RASInsider/RAS-UserPortal-SkinManager/actions/runs/37590811033) completed successfully on **Microsoft Windows Server 2025** (`windows-2025-vs2026` runner image). It tested implementation commit `9af5b8c56d0042ea2a36f85a7d315087d6d9a672`:

- 34 / 34 parser/filesystem fixture checks passed.
- Pester 6.2.0: 14 / 14 tests passed.
- PSScriptAnalyzer 1.25.0: passed with the documented repository settings, including 5.1 syntax compatibility.

This adds real Windows **local fixture** execution of file replacement/transaction code. It does not test the Parallels install directory's actual ACLs, installed RASAdmin, WinRM remoting or a live RAS Farm. No Gateways or RAS Theme were modified. The subsequent evidence-only documentation change does not alter tested implementation code.

## Recorded prototype and read-only lab inspection

The user's recorded baseline is **Parallels RAS 22.0 Technical Preview build 28102**, with static root `C:\Program Files (x86)\Parallels\ApplicationServer\2XHTML5Gateway\www`, independent `/userportal/rasinsider.css`, dark/glass header/login/launcher, blue active underline and supporting controls. This was prior user lab work.

Read-only inspection of existing browser tabs for the lab's sign-in and apps pages confirmed:

- The independent CSS link is present alongside product stylesheets.
- `[data-testid="app-header"]`, `.login-container .login-form[class]`, `#launcher` and the launcher control selectors used in the shipped template exist.
- Inline header logo uses `fill=currentColor`; its temporary `viewBox` was `0 0 117 32`. The shipped contextual selector does not depend on that viewBox or replace the logo.
- Existing panel gradient: 145 degrees, stops 0%/55%/100%, recorded RGBA colors; radius 22px; panel blur 28px with 150% saturation.
- Existing header background: `rgba(5,12,32,.88)`, with header blur observed at 24px. The manager's configurable common default blur is 28px.
- Existing login/launcher borders use the recorded blue at alpha .65/.55, respectively; the manager preserves those presentation values.

No lab input, RAS Theme, portal file, service or prototype was changed during inspection. No proprietary DOM/SVG source, user identity, lab hostname or screenshots are redistributed as project assets. `examples/preview.html` is original synthetic markup, not the product application or evidence of deployment.

## API evidence

Exact cmdlets/properties were checked against authoritative Parallels documentation; see [MULTI-GATEWAY.md](MULTI-GATEWAY.md). Installed RASAdmin help/runtime contracts are checked by the implementation when launched in the lab. No RASAdmin module was installed on the macOS execution host, and no live Farm authentication/discovery was performed here.

## Remaining lab acceptance tests

- Run the matching RASAdmin module on Windows; capture sanitized module version/help and real Site/Gateway property/AgentState/AgentVer output.
- Validate the actual physical index/CSS path-to-URL mapping and current file encoding on build 28102.
- Reconcile/archive the existing working prototype before installation; prove migration does not lose unrelated inline/index changes.
- Exercise Install/Change, Re-apply, Status and Restore on the Windows lab; check Windows elevation/ACL behavior, WinRM authentication and file replacement semantics.
- Deploy to at least two actual Gateways, verify directly served CSS/index and HALB pool presentation; exercise a safe connectivity/commit failure and recovery.
- Change RAS Theme logo, wallpaper, favicon, title and text; confirm RAS remains their owner before/after install and restore.
- Review shipped CSS on sign-in/launcher, actual active tab, search, breadcrumb, list/tile, hover, keyboard focus, disabled/error states, responsive widths and backdrop-filter fallback. Check contrast with actual wallpaper.
- Simulate upgrade hook loss on lab fixtures first; if a real product upgrade is independently authorized later, test re-apply/restore against that upgraded current index and document the new build as unverified until tested.

The GitHub Windows workflow runs ordinary fixture/Pester/static checks only. Its existence is not evidence of a RAS lab run. This release is a preview with live integration validation pending.
