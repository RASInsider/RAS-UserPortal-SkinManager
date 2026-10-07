# RAS User Portal Skin Manager

**Independent community project by RASInsider. Not affiliated with, endorsed by or supported by Parallels. This modifies local User Portal presentation and is not an official supported extension.**

**Development preview 0.1.1-dev. Independent and unsupported.** The current standalone script allows RAS 21.2.x and RAS 22.0 Technical Preview build 28102. Allowing a version is not a claim that every build has been tested. The original presentation baseline is build 28102. The eleven built-in themes were deployed and captured on a real RAS 21.2.2 build 27429 lab with RASAdmin 5.0; the live scope is one Site and one separate Secure Gateway. Read [validation evidence](docs/VALIDATION.md).

The existing **v0.1.0** tag/package is unchanged and does not contain this development update. For the new themes, download the current source PS1 after review; do not expect the old release archive to contain them.

A standalone PowerShell manager for consistent presentation across discovered RAS Secure Gateways. RAS owns logos, wallpaper, favicon, title and text; this tool owns an independent stylesheet and a small marked HTML hook. Compiled product bundles and RAS configuration are untouched.

## Quick start

1. Download `RAS-UserPortal-SkinManager.ps1` from the [preview release](https://github.com/RASInsider/RAS-UserPortal-SkinManager/releases/tag/v0.1.0), review it and check its SHA-256 against `SHA256SUMS.txt`.
2. Use an elevated **Windows PowerShell 5.1** console on an administration machine with the matching installed **RASAdmin API 2.0** module. The script parses on PowerShell 7; live RASAdmin execution on PowerShell 7 is unverified.
3. Use existing authenticated **WinRM/PowerShell remoting** access to all selected Windows Gateways. Negotiate authentication is used; HTTPS can be selected with `-UseSSL`. No CredSSP, insecure certificate bypass or changes to TrustedHosts/firewall/services are performed.
4. Validate the actual physical portal root and index on every target and prove that the root serves `/userportal/`. Default recorded root: `C:\Program Files (x86)\Parallels\ApplicationServer\2XHTML5Gateway\www`, default physical index `index.html`. These are inputs to verify, not automatic routing discovery. Use `-PortalRoot` / `-IndexRelativePath` if the installation differs. `rasinsider.css` is placed directly inside that root; the hook URL is `/userportal/rasinsider.css`.
5. Preserve an existing working prototype. Unmarked CSS links are deliberately refused; follow [migration and recovery](docs/RECOVERY.md). Never overwrite unknown prototype files just to make installation pass.
6. Inspect Status first, then preview and deploy in the lab:

```powershell
.\RAS-UserPortal-SkinManager.ps1 -Action Status -LicensingServer ras-license.example.test -AllSites

.\RAS-UserPortal-SkinManager.ps1 -Action Install -LicensingServer ras-license.example.test `
  -AllSites -Preset 'Dark Glass' -MappingValidated -WhatIf

.\RAS-UserPortal-SkinManager.ps1 -LicensingServer ras-license.example.test -MappingValidated
```

The final command opens the interactive menu. Select scope from **RAS-discovered** Sites/Gateways: `A`, `S:1,2` or `G:10,11`. No manual host inventory is accepted. Every selected node must pass pre-flight; an unreachable/unsupported selected node aborts changes. Partial scopes warn about shared HALB consistency.

The script is unsigned in this preview. Follow your organization's signing/execution policy. If appropriate, review the downloaded file before unblocking that file only; do not weaken global execution policy.

## Actions and presets

| Menu | Behavior |
| --- | --- |
| Install / Change | Choose built-in preset or validated Custom values |
| Re-apply | Use each selected Gateway's saved configuration to repair hook/CSS |
| Restore Original | Remove the managed hook from the **current** index and manager CSS |
| Status | Read-only file/hash/config inspection per discovered target |
| Exit | Leave the manager |

Embedded presets: **Dark Glass, Midnight Blue, Light Glass, RASInsider, Graphite, Forest, Warm Ivory, Bordeaux, Aubergine, Liquid Glass and Ruby**, plus **Custom**. See [theme palettes and exact menu choices](docs/THEMES.md). The main PS1 requires no sibling files; JSON examples are optional imports. Re-apply preserves per-Gateway saved skins rather than silently homogenizing intentionally different Sites. Use Install/Change with one preset to make a selected pool consistent.

```powershell
# Select multiple Sites or a discovered Gateway subset.
.\RAS-UserPortal-SkinManager.ps1 -Action Install -LicensingServer ras-license.example.test `
  -SiteId 1,2 -Preset 'Midnight Blue' -MappingValidated

.\RAS-UserPortal-SkinManager.ps1 -Action Install -LicensingServer ras-license.example.test `
  -GatewayId 10,11 -SkinFile .\skins\custom-example.json -MappingValidated

.\RAS-UserPortal-SkinManager.ps1 -Action Reapply -LicensingServer ras-license.example.test `
  -AllSites -MappingValidated

.\RAS-UserPortal-SkinManager.ps1 -Action Restore -LicensingServer ras-license.example.test `
  -AllSites -MappingValidated
```

`-RASCredential` and `-RemoteCredential` accept existing `PSCredential` objects. Otherwise RAS credentials are prompted securely; WinRM uses the current Windows identity. Credentials are not persisted. `-AcceptDrift`, `-AdoptPrototype` and `-AllowUnverifiedBuild` require deliberate review; see recovery documentation. `-Confirm:$false` is available only when an administrator intentionally chooses unattended execution. Exit code 0 means the requested operation returned normally; 1 means failure requiring the detailed per-target/journal report.

## Safety and limitations

- All-target pre-flight → all-target snapshots/staging → live commits → all-target verification → lock finalization.
- Compensation rollback uses immediate transaction snapshots and refuses to overwrite unrelated concurrent edits or upgrades. A distributed rollout has a transition window; it is not globally atomic and does not automatically drain HALB nodes.
- Restore never blindly copies an old product index backup over the current installation. Upgrade re-apply validates current files and saved settings.
- State, transactions/backups and logs live in `%ProgramData%\RASInsider\RAS-UserPortal-SkinManager\` on each target and the coordinator. Backups are retained for manual review; there is no automatic retention cleanup in v0.1.0.
- Existing unmarked links, duplicate/malformed markers, unexpected content inside a marker, conflicting state identities, reparse points and unsupported index encodings abort automatic edits.
- WinRM is the implemented transport. SMB is a possible future adapter, not a shipped feature. IPv6 literal hostnames, Linux Gateways and automatically inferred HALB membership are outside this preview.
- Local file/hook/hash verification is implemented. Live deployment, served CSS and browser palette captures are documented for the tested single-Gateway lab. RAS Theme changes, broader accessibility coverage and other Windows ACL/runtime environments still require validation. The script does not infer those from a successful file write.

Read [how it works](docs/HOW-IT-WORKS.md), [custom skins](docs/CUSTOM-SKINS.md), [multi-Gateway discovery](docs/MULTI-GATEWAY.md), [recovery](docs/RECOVERY.md) and [validation](docs/VALIDATION.md).

## Development

```powershell
# Requires no additional module; local fixtures only.
pwsh -NoProfile -File .\tests\Run-Checks.ps1

# If installed from the official PowerShell Gallery:
Invoke-Pester .\tests\Manager.Tests.ps1
Invoke-ScriptAnalyzer .\RAS-UserPortal-SkinManager.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
```

The optional Windows CI workflow runs parser/fixture tests and Pester. It does not connect to a RAS Farm. MIT applies to original project work only; no proprietary Parallels code/assets are included.
