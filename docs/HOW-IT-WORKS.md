# How it works

RASAdmin is queried read-only. No `Set-RAS*`, `Invoke-RASApply`, Theme edits or service changes are used. The discovered inventory is the only source for deployment target identities.

The manager generates one deterministic UTF-8 stylesheet using embedded CSS and validated `--ri-*` variables. The stylesheet resides at `<PortalRoot>\rasinsider.css` and is requested as `/userportal/rasinsider.css?v=<SHA-256>`. An administrator must confirm the physical URL mapping before deployment. The script does not guess whether `/userportal` is an alias or subdirectory.

A minimal block is inserted immediately before the closing `head` in the physical index, or replaces the one existing recognized block:

```html
<!-- RASINSIDER-SKIN-MANAGER:BEGIN -->
<link rel="stylesheet" href="/userportal/rasinsider.css?v=<SHA-256>">
<!-- RASINSIDER-SKIN-MANAGER:END -->
```

The actual hash is 64 lowercase hexadecimal characters. Markers, link syntax and block content are checked before editing. Unrecognized content is never deleted automatically. No scripts are injected; no compiled JS/CSS bundles are edited. UTF-8 (with/without BOM) and BOM-marked UTF-16 LE/BE are supported, preserving BOM/newlines and unrelated index content. Other/ambiguous encodings are refused.

## Ownership

RAS continues to supply wallpaper, logo, favicon, title and text. There are no image URLs, replacements or CSS `content` overrides. An inline RAS header SVG uses `currentColor`; CSS sets color in the existing contextual logo container. The temporary prototype `viewBox` selector is not used by the manager. Uploaded image/SVG assets retain their own content.

Stable anchors include `[data-testid="app-header"]`, `.login-container .login-form[class]` and `#launcher`. Read-only inspection of the working prototype also confirmed launcher `.launcher-tabs .tab.current`, `[data-testid="apps-launcher-search"]`, `.breadcrumbs`, `.launcher-breadcrumb-root`, `.list .app`, `.tile .app`, and the application-name/description test IDs. No generated `data-v-*` scope attribute is used.

Styles cover dark/glass surfaces, current tab underline, search, breadcrumb, list/tile hover, text and keyboard focus. Translucent backgrounds still provide a color fallback if backdrop filtering is unavailable. A full browser accessibility/Theme-change test of the shipped CSS remains a lab requirement; read-only inspection of an existing prototype is not a new deployment test.

## State and transaction lifecycle

Each Gateway stores `state.json`, an active transaction lock and retained `transactions/<id>/` manifests plus before/after snapshots beneath ProgramData. Coordinator journals/logs are under the same project's `coordinator/` directory. Farm identity is the normalized Licensing Server connection name, plus API Site/Gateway IDs; it is not a claimed RAS Farm GUID. Use the same Licensing Server name on later runs.

Pre-flight creates only isolated capability probes and manager state directories, not live portal edits. All chosen nodes must pass. Preparation acquires an exclusive ownership lock and backs up current index/CSS/state. Every target stages before the first live commit. Files are replaced from same-directory temporary files using `File.Replace` (or moved when previously absent), preserving destination ACL semantics on Windows. Restore removes the hook before deleting CSS; install writes CSS before the hook.

SHA-256 snapshots are rechecked before commit. The worker persists write intent before each replacement and compensates failures by restoring only a matching immediate snapshot. It refuses unrelated third-party edits. Verification compares all expected file hashes; the coordinator also rechecks selected no-op targets. Successful runs release locks only after verification. Interrupted or incomplete runs require journal recovery.

There is no global atomic transaction across Windows hosts. Sequential commits can temporarily show different presentation behind HALB, and a disconnect may prevent immediate rollback. The tool records this rather than promising otherwise.

Status reads current files and saved hashes. Installation/re-apply can be a byte-preserving no-op. Missing hooks after upgrade are repaired using saved skin settings and the new current index. Other drift requires review. Unverified builds require explicit lab opt-in. Recovery never assumes that an older full index is the right version to restore.
