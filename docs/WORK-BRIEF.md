# RASInsider RAS User Portal Skin Manager — Complete Work Implementation Brief

## Mission

Build and deliver the community project **RASInsider/RAS-UserPortal-SkinManager**, then publish its first GitHub preview release **v0.1.0**. This is an execution assignment: implement the software, documentation, validation, repository workflow and release. Do not deliver only a proposal or scaffold.

Create the repository in the GitHub organization **RASInsider**, or use the existing repository with that exact name. Inspect its contents and history before changing anything. Preserve existing useful work. Use a development branch and pull request where practical; use `codex/initial-preview` unless repository instructions require another name. Finish the authorized publication workflow using available credentials. If access is missing, complete everything possible locally and report the precise blocker without claiming publication occurred.

All public code, comments, configuration examples, console/UI messages, README, documentation, PR descriptions and release notes must be **in English**.

### Context and evidence boundary

This brief consolidates the user's explicit validated prototype findings and architectural decisions, plus the available conversation record. The retrieved conversation confirms the farm-aware design, RAS API discovery, multi-Site selection, all-target pre-flight, branding ownership, restore/re-apply, GitHub deliverables and release goal. Earlier detailed prototype exchanges were not exposed by the conversation retrieval. Treat the concrete prototype findings supplied below as the project's recorded lab baseline; independently record what you actually inspect and test. Do not present requested functionality or illustrative snippets as newly executed tests.

## Non-negotiable architecture

1. **Parallels RAS owns dynamic theme content and assets:** logo, wallpaper, favicon, title and text. Skin Manager owns presentation only. Preserve RAS Theme configuration and its rendering behavior, including when an administrator changes the RAS Theme after installation.
2. **Never edit, replace, rebuild or redistribute compiled Parallels JavaScript or CSS bundles.** Do not patch Vue application code or copy proprietary Parallels assets into this repository.
3. Use one independent stylesheet served at **`/userportal/rasinsider.css`**, loaded by a minimal hook in the **physical portal `index.html`**. Validate the actual URL-to-file mapping before writing. The validated static root is `C:\Program Files (x86)\Parallels\ApplicationServer\2XHTML5Gateway\www`; do not assume every installation uses the same drive/path or that a virtual URL is a physical directory.
4. Use distinctive HTML comment markers around the manager-owned stylesheet link. Installation/change/re-apply must leave exactly one managed block. Restore removes only that managed block from the **current** index and removes only manager-owned deployed files.
5. Express presentation through namespaced **`--ri-*` CSS custom properties** and stable contextual selectors. Do not depend on hashed bundles, transient Vue-generated scope identifiers or positional DOM assumptions.
6. Supply a **standalone PowerShell manager**: the main `.ps1` must operate without sibling source files, downloaded runtime code or a repository checkout. Embed defaults, built-in presets and CSS template; external JSON examples are optional imports. The installed RAS module and normal Windows remote administration prerequisites may be required and must be documented.
7. Persist configuration, state, logs and backups under **ProgramData**, for example `%ProgramData%\RASInsider\RAS-UserPortal-SkinManager\`. No persistent manager state in the product install directory except the stylesheet and hook.
8. **Farm-awareness is mandatory in v0.1.0.** RAS API discovers infrastructure; validated Windows remote administration deploys the presentation files. Do not substitute a hand-maintained host list for discovery.
9. Advertise compatibility only for the exact verified baseline: **Parallels RAS 22.0 Technical Preview, build 28102**. Detect and report other builds as unverified; no broad RAS 22/production compatibility claim.

Example managed hook (validate insertion location and physical mapping):

```html
<!-- RASINSIDER-SKIN-MANAGER:BEGIN -->
<link rel="stylesheet" href="/userportal/rasinsider.css">
<!-- RASINSIDER-SKIN-MANAGER:END -->
```

Load after the relevant product styles so intended overrides work. Preserve the rest of the index, including product tags and security-related attributes. If cache busting is needed, use a deterministic manager-owned version/hash query and validate it against the portal's serving behavior.

## Validated lab findings

### Product and portal

- Baseline: **Parallels RAS 22.0 Technical Preview build 28102**.
- Static root: **`C:\Program Files (x86)\Parallels\ApplicationServer\2XHTML5Gateway\www`**.
- A separate stylesheet at `/userportal/rasinsider.css`, injected through physical `index.html`, successfully provides presentation overrides without modifying compiled bundles.
- The application uses Vue/scoped CSS. Recorded stable selector anchors include **`[data-testid="app-header"]`**, **`#launcher`** and **`.login-container .login-form[class]`**. The `[class]` selector raises specificity without hard-coding a generated scope attribute.
- The inline header SVG logo uses **`fill=currentColor`**; its visible color can follow contextual CSS `color`.
- The prototype temporarily targeted the Parallels SVG using its `viewBox`. The exact viewBox value is not provided here. **Do not invent it or make that temporary selector the final API.** Inspect the DOM and prefer stable header/logo context. Never replace the RAS-supplied logo or force arbitrary theme-uploaded images to behave like that inline SVG.

### Validated Dark Glass appearance

| Element/token | Recorded value or behavior |
| --- | --- |
| Header | `rgba(5,12,32,.88)` |
| Panel gradient | `rgba(5,12,32,.94)` → `rgba(12,22,48,.90)` → `rgba(35,18,50,.88)` |
| Accent | `#4B91FF` |
| Border | `#4391FF` |
| Primary text | `#FFFFFF` |
| Secondary text | white at opacity `.55`–`.72` |
| Backdrop blur | `28px` |
| Panel radius | `22px` |
| Surfaces | Dark header, login panel and launcher |
| Navigation | Blue active underline |
| Supporting controls | Dark search, breadcrumb and list rows; blue hover treatment |

The following is a concrete implementation seed using the recorded tokens and known anchors. Gradient direction, border opacity, logo descendant selector and additional control selectors must be reconciled against the existing prototype/DOM; this is not a claim that this exact block was tested verbatim.

```css
:root {
  --ri-header-bg: rgba(5, 12, 32, .88);
  --ri-panel-start: rgba(5, 12, 32, .94);
  --ri-panel-middle: rgba(12, 22, 48, .90);
  --ri-panel-end: rgba(35, 18, 50, .88);
  --ri-accent: #4B91FF;
  --ri-border: #4391FF;
  --ri-text-primary: #FFFFFF;
  --ri-text-secondary: rgba(255, 255, 255, .72);
  --ri-text-muted: rgba(255, 255, 255, .55);
  --ri-blur: 28px;
  --ri-radius: 22px;
}
[data-testid="app-header"] {
  background: var(--ri-header-bg);
  color: var(--ri-text-primary);
  -webkit-backdrop-filter: blur(var(--ri-blur));
  backdrop-filter: blur(var(--ri-blur));
}
.login-container .login-form[class] {
  background: linear-gradient(135deg,
    var(--ri-panel-start), var(--ri-panel-middle), var(--ri-panel-end));
  color: var(--ri-text-primary);
  border: 1px solid var(--ri-border);
  border-radius: var(--ri-radius);
  -webkit-backdrop-filter: blur(var(--ri-blur));
  backdrop-filter: blur(var(--ri-blur));
}
#launcher {
  color: var(--ri-text-primary);
  background: linear-gradient(135deg,
    var(--ri-panel-start), var(--ri-panel-middle), var(--ri-panel-end));
}
```

Inspect actual selectors for active tabs, search input, breadcrumb, list rows, hover, focus, disabled and error states. Scope overrides to the portal, keep selectors understandable and avoid blanket rules for all SVGs/images. Use `!important` only where confirmed cascade behavior requires it. Preserve wallpaper visibility and RAS-supplied content. Provide readable fallback surfaces when backdrop filtering is unavailable. Verify keyboard focus and contrast, not just a screenshot.

## UX requirements

The main interactive menu must provide:

```text
RASInsider RAS User Portal Skin Manager

[1] Install / Change skin
[2] Re-apply current skin
[3] Restore Original
[4] Status
[5] Exit
```

Before a modifying action, show discovered Farm/Sites/Gateways, eligibility, selected scope, chosen skin and the pre-flight result. Permit all Sites, one or more Sites and an explicit subset of discovered Gateways. Clearly warn when selection covers only part of a shared HALB pool; do not claim pool membership unless verified.

Built-in presets: **Dark Glass**, **Midnight Blue**, **Light Glass**, **RASInsider**, **Custom**. Dark Glass must preserve the recorded baseline. The other preset palettes are implementation choices, not previously validated lab findings. Ship coherent defaults, document them and validate them. Custom must support validated colors, opacity, blur and radius, with a preview/summary and clear errors. Prefer structured color input such as `#RRGGBB`, numeric opacity `0..1`, and documented finite blur/radius ranges in pixels. Reject malformed, out-of-range, non-finite and CSS-injection input before rendering CSS. Version the JSON schema and supply import examples.

Re-apply loads saved settings, rediscovers current topology, shows changes and restores the hook/CSS after upgrade or drift. It must not silently target newly discovered servers or overwrite unknown prototype files. Restore is idempotent and keeps RAS branding/content. Status is read-only, reports per-target build, hook count/state, CSS presence/hash, desired versus actual preset/config, index drift, accessibility and recovery state. Report partial/unreachable state honestly.

Useful non-interactive parameters, `-WhatIf`/`-Confirm` support and meaningful exit codes are desirable for administration and testing, but may not replace the required interactive workflow.

## Farm/multi-Gateway requirements

### Verify discovery before coding against it

Inspect the **actual installed Parallels RAS PowerShell/RASAdmin module and help**, and/or authoritative Parallels documentation. Use read-only module/command/help inspection first. Do not guess cmdlet names such as `Get-RASSecureGateway`, connection parameters or output properties.

Verify and document:

- Module name, version, location, supported PowerShell edition/version and required privileges.
- Authentication/session establishment and cleanup, without logging credentials.
- Exact commands/API calls and parameters to identify the Farm, enumerate Sites and enumerate Secure Gateways.
- Exact returned properties used for stable Farm/Site/Gateway identity, hostname, role, portal eligibility and version/build where available.
- How disabled/offline nodes, duplicate names, multiple Sites and missing properties are handled.
- Which properties come from RAS API and which checks come from remote filesystem/version inspection.

Record evidence provenance, documentation links/version and sanitized command/help/output excerpts. The discovery mechanism must be implemented, not merely described. If neither module nor authoritative API details are available, do not invent an adapter: complete independent work and identify the blocking prerequisite explicitly.

### Deployment and consistency

RAS API is the source of truth for target identities. Resolve and validate hosts from that inventory. Separate discovery from transport. Use authenticated, safe Windows administration such as **SMB administrative shares (`C$`/Admin$ as applicable) or WinRM**, only after validating connectivity, permissions, paths and availability. Admin$ maps to the Windows directory; do not incorrectly treat it as the C: root. Do not enable services, weaken security, change firewall rules or embed credentials to make transport work.

**Pre-flight ALL selected Gateways before modifying ANY deployed portal file.** Check identity, connectivity, administrative rights, actual install path, exact build, portal/index existence, encoding, directory/write capability, free space, backup/state availability, marker integrity, collisions, existing prototype and unexpected drift. Temporary capability probes must be isolated, cleaned up and must not alter live portal behavior. Freeze the selected target set for the transaction.

If any selected target fails, abort before live deployment and clearly report that no portal target was modified. Do not silently skip failed servers or deploy only to reachable nodes. HALB consistency is a central requirement.

After successful pre-flight, snapshot and stage the change on every target before committing live files. Revalidate snapshot hashes immediately before mutation to catch intervening changes. Use safe per-file replacement and order operations so a newly installed hook does not reference a missing CSS file. Verify every target's committed files, hook count, hashes and effective configuration; validate served behavior where lab routing permits.

A distributed filesystem rollout is not globally atomic. Document this limit, minimize the transition interval and do not advertise an impossible zero-window transaction. On failure, stop further commits and run verified compensating rollback for every changed target. Persist a transaction journal with stages and per-target outcomes so interruption/restart can be reconciled. Report partial rollback and exact recovery actions; never label a mixed farm healthy.

## Safety/rollback

- Check supported Windows/PowerShell environment and elevation/remote rights early. Resolve paths safely and use literal-path operations. No wildcard deletion or broad recursive cleanup.
- Use terminating error handling at mutation boundaries, actionable English errors, nonzero failure exit codes and timestamped, correlated logs. Never store passwords/tokens in logs, JSON, commits or release artifacts.
- Preserve index encoding/BOM and newline convention where feasible. Detect unsupported/ambiguous encodings and fail safely. Avoid unnecessary full-file reserialization.
- Maintain versioned ProgramData config/state plus per-Gateway identity, selected scope, product build, skin/schema version, CSS hash, index baseline/post-change hashes and transaction metadata. Use SHA-256 and deterministic CSS rendering.
- Serialize concurrent manager runs or detect conflicts. A changed index/hash must trigger reinspection; do not overwrite another administrator's concurrent edits.
- Back up the current affected files before mutation, with timestamp, hash and transaction identity. Backups are for recovery, not a license to blindly replace a newer product index.
- **Clean Restore Original operates on the current index:** remove only recognized manager markers/link, preserving current Parallels upgrade output and unrelated edits. Never restore an old full index backup over a newer RAS installation by default.
- Transaction rollback may restore an immediate pre-transaction snapshot only after confirming it has not been superseded by an upgrade or unrelated concurrent change. Otherwise stop and provide surgical recovery.
- Detect missing hook/CSS, duplicate or malformed markers, CSS tampering, saved-config mismatch and product upgrade. Repair through validated re-apply; do not claim automatic cross-version compatibility.
- Preserve/reconcile any working prototype before first install. Inspect the current CSS/hook, compare with desired output and archive it safely. Adopt a recognizable existing hook only through explicit migration logic. Unknown CSS/link collisions must not be overwritten silently.
- Never alter RAS Theme configuration, proprietary bundles or service settings as part of skin deployment. Avoid service restarts unless demonstrated necessary and explicitly documented/authorized.
- Recovery documentation must cover failed pre-flight, mid-rollout failure, interrupted process, inaccessible target, failed rollback, upgrade, lost/corrupt state, unknown hook and manual surgical removal.

## Repository deliverables

```text
RAS-UserPortal-SkinManager/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── RAS-UserPortal-SkinManager.ps1
├── skins/
│   ├── dark-glass.json
│   ├── midnight-blue.json
│   ├── light-glass.json
│   ├── rasinsider.json
│   └── custom-example.json
├── docs/
│   ├── HOW-IT-WORKS.md
│   ├── CUSTOM-SKINS.md
│   ├── MULTI-GATEWAY.md
│   └── RECOVERY.md
├── tests/
└── screenshots/
```

Use **MIT LICENSE unless an actual repository/legal constraint contraindicates it**; explain any deviation. License only original project work. Add appropriate ignore rules. Screenshots/examples are useful where available, but must be sanitized of identities, credentials and proprietary asset redistribution concerns. Do not fabricate screenshots or lab evidence.

README must prominently state: **Independent community project by RASInsider; not affiliated with, endorsed by or supported by Parallels. Modifies the local User Portal presentation and is not an official supported extension. Tested baseline: Parallels RAS 22.0 Technical Preview build 28102 only.** Repeat material limitations in release notes.

Document prerequisites, execution policy/signing considerations without recommending global policy weakening, standalone installation, menu usage, discovery prerequisites, remote transport, scope selection, presets/custom schema, Theme ownership, restore/recovery, upgrade repair and limitations. Explain exact verified discovery commands/properties in MULTI-GATEWAY.md. CHANGELOG must match the actual release.

## Implementation/testing plan

1. Inspect repository, tools/authentication and accessible lab read-only. Inventory existing prototype and preserve it. Verify RAS discovery and physical portal mapping before committing implementation assumptions.
2. Implement standalone configuration/CSS generation, presets/custom validation and surgical marker handling. Separate discovery, planning, pre-flight, staging, commit, verification and rollback internally so they can be tested.
3. Implement verified farm inventory and scope selection, remote adapters, state/hashes/journal and all required menu actions. Embed runtime defaults/template in the main script.
4. Add documentation and meaningful automated tests. Use **PSScriptAnalyzer and Pester if available**. Otherwise run available PowerShell parser/syntax and static checks, explicitly reporting unavailable tools. Do not treat static inspection as Windows runtime validation.
5. Exercise important failure paths with fixtures/mocks: malformed input, duplicate hooks, encoding, upgrade-current-index restore, repeated install/re-apply/restore, all-target pre-flight failure with zero live writes, failure after one target commits, rollback failure, concurrency drift and interrupted journal recovery.
6. Test safely in the accessible lab: establish a restorable baseline; preserve current working prototype; install/change/re-apply/restore/status; validate Dark Glass login/header/launcher and supporting controls; change the RAS Theme logo/wallpaper/favicon/title/text and prove content remains RAS-owned; test multiple Gateways/Sites and consistency where actually available.
7. Simulate upgrade behavior safely on fixtures or an explicitly suitable lab: changed current index, removed hook, preserved config, repair and clean restore. Label simulated versus actual product upgrade tests. Never perform an unrequested product upgrade merely to obtain evidence.
8. Inspect diffs for proprietary content/secrets, finalize PR/docs and publish a release from the validated commit. If a mandatory capability cannot be exercised, disclose it as unverified; do not replace it with invented success.

Keep a concise validation record with command/tool versions, result, actual targets/build, scope and limitations. If lab access is absent, still finish implementation, available checks, documentation and an honestly qualified preview; do not claim live lab tests. If discovery implementation itself is blocked by unavailable verified API information, report that acceptance gap explicitly rather than declaring the project complete.

## Acceptance criteria

- [ ] Repository exists at `RASInsider/RAS-UserPortal-SkinManager`; public project content is English and contains no proprietary Parallels code/assets or secrets.
- [ ] Main PS1 works standalone with documented platform/module prerequisites and contains all five menu actions and five presets.
- [ ] Dark Glass uses the recorded tokens and behavior; Custom validates structured input before CSS generation.
- [ ] Only independent CSS and a minimal marked current-index hook implement the skin; repeated actions are idempotent.
- [ ] RAS remains owner of dynamic branding and Theme changes remain functional.
- [ ] Actual verified RAS API discovery covers Farm/Sites/Secure Gateways; exact commands and properties are documented.
- [ ] Scope supports multiple Sites/Gateways; every selected target passes pre-flight before any live portal mutation.
- [ ] Deployment stages, verifies all targets, journals progress and implements compensating rollback/recovery with truthful per-target status.
- [ ] ProgramData holds config/state/logs/backups; hashes detect drift and upgrade-related hook loss.
- [ ] Restore surgically cleans the current index and cannot blindly overwrite a newer product index with an old backup.
- [ ] Prototype migration, elevation, paths, encoding, errors, concurrent writes and credentials are handled safely.
- [ ] Required files, license, recovery docs and useful examples exist; checks and actual lab evidence are recorded honestly.
- [ ] Preview tag/release `v0.1.0` points to the delivered commit; unsupported status, exact baseline and remaining limitations are prominent.

## Release requirements

Publish the first GitHub **prerelease/preview** as **v0.1.0**. Include the standalone PS1, useful preset examples and a source archive/package where appropriate; supply SHA-256 checksums for distributed artifacts. Ensure artifacts correspond to the tagged commit and exclude local state/backups/secrets/proprietary files.

Release notes must cover installation, prerequisites, exact tested build, supported workflow, verified discovery method, available multi-Gateway evidence, RAS branding preservation, upgrade/re-apply, restore/recovery and all known limitations. Distinguish prototype baseline from tests executed for this release. Do not imply a Parallels endorsement, general version compatibility or a globally atomic deployment.

Use a reviewable PR where practical. Do not destroy existing branches/tags or overwrite an existing v0.1.0 release; inspect and reconcile first. Complete publication within authorized access, or state precisely what remains blocked and provide the ready artifacts/PR.

## Final report

Provide a concise, factual completion report containing:

1. Repository URL and implemented deliverables.
2. Development branch, commit SHA, PR URL and merge state where applicable.
3. `v0.1.0` tag/release URL and artifact/checksum locations, or exact publication blocker.
4. Exact verified RAS module/API discovery mechanism, cmdlets/parameters and properties, with evidence source.
5. Checks actually run, tool versions and results; actual lab tests, tested product build and Gateway/Site count. Clearly distinguish mocks/static checks/simulations from live validation.
6. Existing prototype preservation/migration outcome and rollback/recovery results.
7. Known limitations, failed/unverified acceptance items and concrete remaining TODOs. Do not report full completion if mandatory implementation is missing.

**Execute the work end-to-end: implement, verify, document, deliver the repository workflow and publish the first preview release. Do not stop at recommendations or planning.**
