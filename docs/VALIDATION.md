# Validation evidence — v0.1.0 preview

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
