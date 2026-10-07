# v0.1.0 — First preview

Independent community project by RASInsider; not affiliated with, endorsed by or supported by Parallels. Not an official supported extension.

**Recorded prototype baseline: Parallels RAS 22.0 Technical Preview build 28102 only. Live Windows deployment and RASAdmin integration validation are pending.** No broad compatibility or production support claim.

## Included

- Standalone `RAS-UserPortal-SkinManager.ps1` with interactive Install/Change, Re-apply, Restore Original, Status and Exit.
- Dark Glass, Midnight Blue, Light Glass, RASInsider and Custom, embedded CSS/presets and optional JSON examples.
- Documented RASAdmin discovery: `New-RASSession`, `Get-RASSite`, per-Site `Get-RASGateway -SiteId`, `Get-RASGatewayStatus -Id`, `Get-RASVersion`, `Remove-RASSession`, with runtime contract checks.
- Authenticated WinRM deployment, all-target pre-flight/staging, SHA-256 verification, transaction journals and compensating rollback/recovery.
- Minimal marked current-index hook; independent `/userportal/rasinsider.css`; RAS-owned branding remains intact; no compiled bundle edits or proprietary assets.

## Install

Download/review the standalone PS1 and compare `Get-FileHash -Algorithm SHA256` with `SHA256SUMS.txt`. Run in an elevated Windows PowerShell 5.1 console with the matching RASAdmin module and existing administrative WinRM access to all selected Gateways. Validate the physical portal root/index mapping to `/userportal/` before supplying `-MappingValidated`. Follow local signing/execution policy.

```powershell
.\RAS-UserPortal-SkinManager.ps1 -Action Status -LicensingServer ras-license.example.test -AllSites
.\RAS-UserPortal-SkinManager.ps1 -LicensingServer ras-license.example.test -MappingValidated
```

Use only an appropriate lab. Preserve/reconcile an existing prototype first. Read README and docs/RECOVERY.md before changing portal files.

## Validation and limitations

Locally: 34 filesystem/parser checks and 14 Pester tests passed on PowerShell 7.6.6/macOS; PSScriptAnalyzer 1.25.0 and 5.1 syntax compatibility checks passed with documented settings. Two-Gateway transaction/failure cases used local fixtures and mocked transport. Existing lab pages/prototype CSS were inspected read-only.

Pending: installed RASAdmin/build-28102 runtime, real Windows ACL/WinRM deployment, real multi-Gateway/HALB rollback, served CSS/cache behavior and RAS Theme-change/accessibility validation. See docs/VALIDATION.md.

WinRM only; no SMB adapter, Linux nodes, IPv6 literal hosts, automatic HALB pool discovery, automatic backup retention or globally atomic rollout. Sequential commits have a transition window. Unknown/ambiguous prototype hooks and unverified builds are deliberately refused by default.

## Recovery

Restore surgically removes the manager hook from the current index, preserving current product changes. Re-apply uses saved configuration after upgrade/drift review. Interrupted transactions retain snapshots/locks and can be recovered with the reported `-RecoverTransaction <id>`. Rollback refuses unrelated concurrent changes; inaccessible/ambiguous targets require documented manual recovery. Never blindly restore an old product index over a new build.

License: MIT for original project work. No proprietary Parallels assets/code included.
