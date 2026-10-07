# Farm discovery and multi-Gateway deployment

## Verified documentation contract

Official Parallels documentation was inspected on 2026-10-07. The unversioned PowerShell guide links to v21 source material; it is **documentation evidence**, not proof that build 28102's installed module was executed. The script checks installed commands/parameters and required returned properties at runtime and fails on mismatch.

| Step | Exact command | Used contract |
| --- | --- | --- |
| Module | `Import-Module RASAdmin` | API 2.0; matching module/product version required |
| Authenticate | `New-RASSession -Server <LicensingServer> -Username <UPN> -Password <SecureString>` | Existing secure credentials; no Force/apply/license edits |
| Version | `Get-RASVersion` | Documented string output; reported as Farm version |
| Sites | `Get-RASSite` | Site `Id`, `Name`; returns available Sites |
| Gateways per Site | `Get-RASGateway -SiteId <Site.Id>` | Gateway `Id`, `SiteId`, `Server`, `Enabled`, `Mode` |
| Gateway health/build | `Get-RASGatewayStatus -Id <Gateway.Id>` | `AgentVer`, `AgentState` |
| Session cleanup | `Remove-RASSession` | Called in finally after successful session creation |

`Get-RASGateway` without `-SiteId` defaults to the Licensing Server Site, so the manager explicitly enumerates **each Site**. `EnableUserPortal`, when present, is shown as inventory information; inherited Theme/Gateway defaults mean it is not used as an invented definitive eligibility test. Actual portal/index checks happen remotely. Enabled Normal-mode nodes with API state `OK` are required for deployment. Status can inspect disabled/unhealthy nodes. The exact per-Gateway `AgentVer` is checked for 22.0 and build 28102; Farm version is not substituted for every node's version.

The script uses the Licensing Server connection name as a persisted Farm key (normalized lowercase), not an invented Farm Name/GUID property. Documented `Get-RASFarmSettings` was considered but no unnecessary settings or undocumented identity field is used. Use one consistent connection name to avoid state identity conflicts.

### Official sources

- [RAS PowerShell installation/API versions](https://docs.parallels.com/landing/ras-admin-guide/v20-en-us/parallels-ras-20-administrators-guide/parallels-ras-apis/ras-powershell-api)
- [New-RASSession](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/commands/new-rassession)
- [Get-RASVersion](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/commands/get-rasversion)
- [Get-RASSite](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/commands/get-rassite) and [Site properties](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/types/site)
- [Get-RASGateway](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/commands/get-rasgateway) and [Gateway properties](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/types/gateway)
- [Get-RASGatewayStatus](https://docs.parallels.com/landing/ras-powershell-api-guide/v20/parallels-ras-powershell-admin-module/commands/get-rasgatewaystatus) and [GatewaySysInfo properties](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/types/gatewaysysinfo)
- [Remove-RASSession](https://docs.parallels.com/landing/ras-powershell-api-guide/parallels-ras-powershell-admin-module/commands/remove-rassession)

On the lab administration host, inspect `Get-Module -ListAvailable RASAdmin`, `Get-Command -Module RASAdmin`, `Get-Help <command> -Full`, and sanitized `Get-RASSite | Format-List *` / `Get-RASGateway -SiteId <id> | Format-List *`. Record module version and actual property/enum output. Do not use legacy `PSAdmin` aliases or invent replacements when the API differs.

## Scope and transport

Choose all Sites or one/multiple Sites/Gateway IDs from the inventory. Combined Site/Gateway filters intersect; unknown IDs fail. Duplicate target hostnames across inventory are refused to avoid double writes. A failed status query or unverified build blocks modification unless the build alone is explicitly allowed for a reviewed lab.

Authenticated WinRM runs the embedded worker under an administrator context on each Gateway. Sessions are established before writes, using Negotiate and normal certificate validation. No local drive sharing/double-hop is needed: workers read/write local files on their own host. Credentials remain in memory. SMB/Admin$ was an architectural option; v0.1.0 implements **WinRM only**. Do not claim an SMB adapter exists. Admin$ is the Windows directory, not the C: root.

Every selected node passes capability checks and plan validation before any live file changes. Every changing node then locks, snapshots and stages; only after all prepare calls succeed does commit start. Hash verification covers all selected nodes, including no-op nodes. Partial rollbacks retain locks/journals for recovery. No unreachable server is silently skipped.

HALB pool membership is not discovered by this preview, so partial scope always warns. An administrator must ensure the entire relevant pool is selected. The manager does not drain traffic; there is a sequential transition window. For zero mixed presentation during rollout, use your established lab maintenance/traffic management procedure.
