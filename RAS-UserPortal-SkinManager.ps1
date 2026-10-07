#requires -Version 5.1
<#
.SYNOPSIS
Independent community presentation manager for the Parallels RAS User Portal.
.DESCRIPTION
Standalone preview. RASAdmin discovers; authenticated WinRM deploys. Product bundles,
branding assets and RAS configuration are never changed. See README before use.
.PARAMETER MappingValidated
Acknowledges that PortalRoot maps to /userportal/ and IndexRelativePath is the physical
portal index on every selected node. Validate serving/routing in your lab first.
.PARAMETER RecoverTransaction
Roll back an interrupted transaction using its coordinator journal and remote snapshots.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Interactive','Install','Reapply','Restore','Status')][string]$Action = 'Interactive',
    [string]$LicensingServer,
    [PSCredential]$RASCredential,
    [PSCredential]$RemoteCredential,
    [uint32[]]$SiteId,
    [uint32[]]$GatewayId,
    [switch]$AllSites,
    [ValidateSet('Dark Glass','Midnight Blue','Light Glass','RASInsider','Graphite','Forest','Warm Ivory','Bordeaux','Aubergine','Liquid Glass','Ruby','Custom')][string]$Preset = 'Dark Glass',
    [string]$SkinFile,
    [string]$PortalRoot = 'C:\Program Files (x86)\Parallels\ApplicationServer\2XHTML5Gateway\www',
    [string]$IndexRelativePath = 'index.html',
    [switch]$MappingValidated,
    [switch]$AllowUnverifiedBuild,
    [switch]$AcceptDrift,
    [switch]$AdoptPrototype,
    [switch]$UseSSL,
    [ValidateRange(0,65535)][int]$RemotePort = 0,
    [string]$RecoverTransaction
)

$script:RIVersion = '0.1.1-dev'
$script:RIBegin = '<!-- RASINSIDER-SKIN-MANAGER:BEGIN -->'
$script:RIEnd = '<!-- RASINSIDER-SKIN-MANAGER:END -->'

function Test-RIAllowedVersion {
    [CmdletBinding()]
    param([AllowNull()][AllowEmptyString()][string]$Version)
    # RAS may report major/minor only, with the build in parentheses.
    return ($Version -match '^21\.2(?:\.\d+)*(?:\s+\(build \d+\))?$' -or
        ($Version -match '^22\.0(?:\.|\b)' -and $Version -match '\b28102\b'))
}

function Get-RIPreset {
    [CmdletBinding()]
    param([string]$Name = 'Dark Glass')
    $skin = [ordered]@{
        SchemaVersion = 1; Name = $Name
        Header = '#050C20'; HeaderOpacity = 0.88
        PanelStart = '#050C20'; StartOpacity = 0.94
        PanelMiddle = '#0C1630'; MiddleOpacity = 0.90
        PanelEnd = '#231232'; EndOpacity = 0.88
        Accent = '#4B91FF'; Border = '#4391FF'; Primary = '#FFFFFF'
        SecondaryOpacity = 0.72; MutedOpacity = 0.55; Blur = 28; Radius = 22
    }
    switch ($Name) {
        'Midnight Blue' {
            $skin.Header = '#07152B'; $skin.PanelStart = '#091B36'
            $skin.PanelMiddle = '#102D50'; $skin.PanelEnd = '#152943'; $skin.Accent = '#70B8FF'
        }
        'Light Glass' {
            $skin.Header = '#F2F7FF'; $skin.PanelStart = '#FFFFFF'
            $skin.PanelMiddle = '#EFF5FF'; $skin.PanelEnd = '#E7EFFF'
            $skin.Primary = '#15243A'; $skin.Accent = '#175EBA'; $skin.Border = '#175EBA'
            $skin.StartOpacity = 0.96; $skin.MiddleOpacity = 0.96; $skin.EndOpacity = 0.96
            $skin.HeaderOpacity = 0.96; $skin.SecondaryOpacity = 0.85; $skin.MutedOpacity = 0.78
        }
        'RASInsider' {
            $skin.Header = '#090F20'; $skin.PanelStart = '#090F20'
            $skin.PanelMiddle = '#122346'; $skin.PanelEnd = '#201C43'; $skin.Accent = '#7BAEFF'
        }
        'Graphite' {
            $skin.Header = '#181B20'; $skin.PanelStart = '#181B20'
            $skin.PanelMiddle = '#22262D'; $skin.PanelEnd = '#292E36'
            $skin.Accent = '#54C6BE'; $skin.Border = '#4B535F'; $skin.Primary = '#F4F6F8'
        }
        'Forest' {
            $skin.Header = '#10241F'; $skin.PanelStart = '#10241F'
            $skin.PanelMiddle = '#19332B'; $skin.PanelEnd = '#203C33'
            $skin.Accent = '#99C7AC'; $skin.Border = '#567769'; $skin.Primary = '#F0F7F3'
        }
        'Warm Ivory' {
            $skin.Header = '#FAF8F3'; $skin.PanelStart = '#FAF8F3'
            $skin.PanelMiddle = '#F4F0E8'; $skin.PanelEnd = '#EDE7DC'
            $skin.Accent = '#805B35'; $skin.Border = '#C9BCA8'; $skin.Primary = '#302C27'
        }
        'Bordeaux' {
            $skin.Header = '#21191D'; $skin.PanelStart = '#21191D'
            $skin.PanelMiddle = '#2D2027'; $skin.PanelEnd = '#39252E'
            $skin.Accent = '#D6A2B4'; $skin.Border = '#7B5968'; $skin.Primary = '#FAF2F5'
        }
        'Aubergine' {
            $skin.Header = '#292036'; $skin.PanelStart = '#322646'
            $skin.PanelMiddle = '#443458'; $skin.PanelEnd = '#594471'
            $skin.Accent = '#D3B8ED'; $skin.Border = '#9276AE'; $skin.Primary = '#FAF5FF'
        }
        'Liquid Glass' {
            $skin.Header = '#EEF4FC'; $skin.PanelStart = '#FFFFFF'
            $skin.PanelMiddle = '#EDF4FC'; $skin.PanelEnd = '#F4F7FC'
            $skin.Accent = '#0065D0'; $skin.Border = '#FFFFFF'; $skin.Primary = '#17283D'
            $skin.HeaderOpacity = 0.78; $skin.StartOpacity = 0.70
            $skin.MiddleOpacity = 0.64; $skin.EndOpacity = 0.58
            $skin.SecondaryOpacity = 0.80; $skin.MutedOpacity = 0.76
            $skin.Blur = 36; $skin.Radius = 30
        }
        'Ruby' {
            $skin.Header = '#171316'; $skin.PanelStart = '#1B171B'
            $skin.PanelMiddle = '#302026'; $skin.PanelEnd = '#541F2C'
            $skin.Accent = '#FF4053'; $skin.Border = '#AD4051'; $skin.Primary = '#FFF7F8'
            $skin.HeaderOpacity = 0.96; $skin.StartOpacity = 0.96
            $skin.MiddleOpacity = 0.94; $skin.EndOpacity = 0.92
            $skin.SecondaryOpacity = 0.78; $skin.MutedOpacity = 0.68
        }
        'Dark Glass' { }
        'Custom' { }
        default { throw "Unknown preset: $Name" }
    }
    if ($Name -in @('Graphite','Forest','Warm Ivory','Bordeaux','Aubergine')) {
        $skin.HeaderOpacity = 0.96; $skin.StartOpacity = 0.96
        $skin.MiddleOpacity = 0.96; $skin.EndOpacity = 0.96
        $skin.SecondaryOpacity = 0.78; $skin.MutedOpacity = 0.68
        if ($Name -eq 'Warm Ivory') { $skin.SecondaryOpacity = 0.85; $skin.MutedOpacity = 0.78 }
        if ($Name -eq 'Aubergine') { $skin.SecondaryOpacity = 0.82 }
    }
    [PSCustomObject]$skin
}

function Test-RISkin {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Skin)
    $expected = (Get-RIPreset).PSObject.Properties.Name
    foreach ($p in $Skin.PSObject.Properties.Name) {
        if ($p -notin $expected) { throw "Unknown skin property: $p" }
    }
    foreach ($p in $expected) {
        if ($null -eq $Skin.PSObject.Properties[$p]) { throw "Missing skin property: $p" }
    }
    if ($Skin.SchemaVersion -isnot [ValueType] -or $Skin.SchemaVersion -ne 1) { throw 'Unsupported skin schema.' }
    if ($Skin.Name -isnot [string] -or $Skin.Name -notmatch '^[A-Za-z0-9][A-Za-z0-9 _-]{0,63}$') { throw 'Invalid skin name.' }
    foreach ($p in 'Header','PanelStart','PanelMiddle','PanelEnd','Accent','Border','Primary') {
        if ($Skin.$p -isnot [string] -or $Skin.$p -cnotmatch '^#[0-9A-Fa-f]{6}$') { throw "Invalid color: $p (use #RRGGBB)." }
    }
    foreach ($p in 'HeaderOpacity','StartOpacity','MiddleOpacity','EndOpacity','SecondaryOpacity','MutedOpacity','Blur','Radius') {
        $value = $Skin.$p
        if ($value -isnot [ValueType] -or $value -is [bool]) { throw "Numeric value required: $p" }
        $n = [double]$value
        $max = if ($p -eq 'Blur') { 60 } elseif ($p -eq 'Radius') { 48 } else { 1 }
        if ([double]::IsNaN($n) -or [double]::IsInfinity($n) -or $n -lt 0 -or $n -gt $max) { throw "Out of range: $p (0..$max)." }
    }
    $true
}

function ConvertTo-RIRgba {
    param([string]$Color,[double]$Opacity)
    $r = [Convert]::ToInt32($Color.Substring(1,2),16)
    $g = [Convert]::ToInt32($Color.Substring(3,2),16)
    $b = [Convert]::ToInt32($Color.Substring(5,2),16)
    $a = $Opacity.ToString('0.##',[Globalization.CultureInfo]::InvariantCulture)
    "rgba($r,$g,$b,$a)"
}

function Get-RICss {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Skin)
    $null = Test-RISkin $Skin
    $tokens = [ordered]@{
        'header-bg' = ConvertTo-RIRgba $Skin.Header $Skin.HeaderOpacity
        'panel-start' = ConvertTo-RIRgba $Skin.PanelStart $Skin.StartOpacity
        'panel-middle' = ConvertTo-RIRgba $Skin.PanelMiddle $Skin.MiddleOpacity
        'panel-end' = ConvertTo-RIRgba $Skin.PanelEnd $Skin.EndOpacity
        'accent' = $Skin.Accent.ToUpperInvariant(); 'border' = $Skin.Border.ToUpperInvariant()
        'panel-border' = ConvertTo-RIRgba $Skin.Border 0.65
        'launcher-border' = ConvertTo-RIRgba $Skin.Border 0.55
        'fallback-bg' = $Skin.PanelStart.ToUpperInvariant()
        'text-primary' = $Skin.Primary.ToUpperInvariant()
        'text-secondary' = ConvertTo-RIRgba $Skin.Primary $Skin.SecondaryOpacity
        'text-muted' = ConvertTo-RIRgba $Skin.Primary $Skin.MutedOpacity
        'hover' = ConvertTo-RIRgba $Skin.Accent 0.18
        'blur' = ([double]$Skin.Blur).ToString('0.##',[Globalization.CultureInfo]::InvariantCulture) + 'px'
        'radius' = ([double]$Skin.Radius).ToString('0.##',[Globalization.CultureInfo]::InvariantCulture) + 'px'
    }
    $lines = foreach ($key in $tokens.Keys) { "  --ri-${key}: $($tokens[$key]);" }
    # Stable anchors are recorded prototype findings. Semantic descendants are preview
    # candidates and must be checked in the target DOM; no generated Vue scope IDs.
    $body = @'
}
:is([data-testid="app-header"], header.app-header) {
  --prls-header-contrast-color: var(--ri-text-primary) !important;
  background: var(--ri-header-bg) !important;
  color: var(--ri-text-primary) !important;
  -webkit-backdrop-filter: blur(var(--ri-blur)) saturate(150%);
  backdrop-filter: blur(var(--ri-blur)) saturate(150%);
  border-bottom: 1px solid var(--ri-border);
}
/* RAS 21.2 build 27429 uses header.app-header without app-header data-testid. */
/* currentColor belongs to the RAS-supplied inline logo; do not replace assets. */
:is([data-testid="app-header"], header.app-header) [aria-label] > div > svg {
  color: var(--ri-text-primary);
}
.login-container .login-form[class] {
  padding: 2rem;
  background: linear-gradient(145deg, var(--ri-panel-start) 0%, var(--ri-panel-middle) 55%, var(--ri-panel-end) 100%) !important;
  color: var(--ri-text-primary) !important;
  border: 1px solid var(--ri-panel-border);
  border-radius: var(--ri-radius) !important;
  -webkit-backdrop-filter: blur(var(--ri-blur)) saturate(150%);
  backdrop-filter: blur(var(--ri-blur)) saturate(150%);
}
#launcher {
  border: 1px solid var(--ri-launcher-border);
  border-radius: var(--ri-radius);
  -webkit-backdrop-filter: blur(var(--ri-blur)) saturate(150%);
  backdrop-filter: blur(var(--ri-blur)) saturate(150%);
  background: linear-gradient(145deg, var(--ri-panel-start) 0%, var(--ri-panel-middle) 55%, var(--ri-panel-end) 100%) !important;
  color: var(--ri-text-primary) !important;
}
.login-container .login-form[class] label,
#launcher [role="heading"] { color: var(--ri-text-primary); }
.login-container .login-form[class] small,
#launcher small { color: var(--ri-text-secondary); }
.login-container .login-form[class] input:not([type="checkbox"]):not([type="radio"]):not([type="submit"]),
#launcher input[type="search"], #launcher [role="search"] input {
  background: var(--ri-header-bg) !important;
  color: var(--ri-text-primary) !important;
  border: 1px solid var(--ri-border);
}
#launcher input::placeholder { color: var(--ri-text-muted); }
#launcher [aria-label="breadcrumb"], #launcher [aria-label="Breadcrumb"],
#launcher [role="row"] {
  background: var(--ri-header-bg);
  color: var(--ri-text-primary);
}
#launcher [role="row"]:hover, #launcher [role="option"]:hover,
#launcher [role="tab"]:hover { background: var(--ri-hover); }
#launcher [role="tab"][aria-selected="true"],
:is([data-testid="app-header"], header.app-header) [aria-current="page"] {
  color: var(--ri-accent) !important;
  border-bottom: 2px solid var(--ri-accent);
}
#launcher :focus-visible, .login-container .login-form[class] :focus-visible,
:is([data-testid="app-header"], header.app-header) :focus-visible {
  outline: 2px solid var(--ri-accent);
  outline-offset: 3px;
}
/* Confirmed by read-only inspection of the existing RAS 22 prototype DOM. */
#launcher .launcher-tabs .tab { color: var(--ri-text-secondary) !important; }
#launcher .launcher-tabs .tab:hover,
#launcher .launcher-tabs .tab.current { color: var(--ri-text-primary) !important; }
#launcher .tab.current::after { background: var(--ri-accent) !important; border-radius: 4px; }
#launcher [data-testid="apps-launcher-search"] input {
  background: var(--ri-header-bg) !important;
  color: var(--ri-text-primary) !important;
  border: 1px solid var(--ri-border);
  border-radius: 10px;
}
#launcher .breadcrumbs, #launcher .launcher-breadcrumb-root {
  background: var(--ri-header-bg) !important;
  color: var(--ri-text-secondary) !important;
}
#launcher .launcher-breadcrumb-root a { color: var(--ri-text-secondary) !important; }
#launcher .list .app, #launcher .tile .app { border-radius: 10px; }
#launcher .list .app:hover, #launcher .tile .app:hover { background: var(--ri-hover) !important; }
#launcher [data-testid="apps-application-name"] { color: var(--ri-text-primary) !important; }
#launcher [data-testid="apps-application-description"] { color: var(--ri-text-muted) !important; }
.login-container .login-form[class] h1 { color: var(--ri-text-primary) !important; }
.login-container .login-form[class] .logon-message { color: var(--ri-text-secondary) !important; }
.login-container .login-form[class] input { border-radius: 12px; }
.login-container .login-form[class] .button { border-radius: 11px; }
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  :is([data-testid="app-header"], header.app-header), .login-container .login-form[class], #launcher {
    background: var(--ri-fallback-bg) !important;
  }
}
/* No wallpaper, image URL, content, favicon, title or bundle overrides. */
'@
    if ($Skin.Name -eq 'Liquid Glass') {
        # CSS-only glass highlights; RAS remains the owner of all branding assets.
        $body += @'

.login-container .login-form[class], #launcher {
  box-shadow: inset 0 2px 1px rgba(255,255,255,.90), inset 1px 0 1px rgba(255,255,255,.70), inset 0 -1px 1px rgba(255,255,255,.55), 0 22px 55px rgba(16,39,68,.25);
}
:is([data-testid="app-header"], header.app-header) {
  box-shadow: inset 0 1px 0 rgba(255,255,255,.85);
}
#launcher input, #launcher .launcher-search input {
  background: rgba(255,255,255,.65) !important;
  border: 1px solid rgba(255,255,255,.85) !important;
  border-radius: 24px !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.85);
}
'@
    }
    "/* RASInsider Skin Manager $script:RIVersion | $($Skin.Name) | MIT */`n:root {`n" + ($lines -join "`n") + "`n" + $body.Replace("`r`n","`n") + "`n"
}

function Get-RIHash {
    param([AllowNull()][byte[]]$Bytes)
    if ($null -eq $Bytes) { return 'ABSENT' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function ConvertFrom-RIIndex {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $offset = 0; $bom = [byte[]]@()
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) {
        $offset = 3; $bom = [byte[]]@(239,187,191); $encoding = New-Object Text.UTF8Encoding($false,$true)
    } elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 255 -and $Bytes[1] -eq 254) {
        if ($Bytes.Length -ge 4 -and $Bytes[2] -eq 0 -and $Bytes[3] -eq 0) { throw 'UTF-32 index is unsupported.' }
        $offset = 2; $bom = [byte[]]@(255,254); $encoding = New-Object Text.UnicodeEncoding($false,$false,$true)
    } elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 254 -and $Bytes[1] -eq 255) {
        $offset = 2; $bom = [byte[]]@(254,255); $encoding = New-Object Text.UnicodeEncoding($true,$false,$true)
    } else { $encoding = New-Object Text.UTF8Encoding($false,$true) }
    try { $text = $encoding.GetString($Bytes,$offset,$Bytes.Length - $offset) }
    catch { throw 'Index encoding is not valid UTF-8 or BOM-marked UTF-16. No edits made.' }
    if ($text.Contains([string][char]0)) { throw 'NUL bytes in index: unsupported encoding.' }
    [PSCustomObject]@{ Text = $text; Encoding = $encoding; Bom = $bom }
}

function Get-RIHookInfo {
    param([string]$Text)
    $begin = [regex]::Matches($Text,[regex]::Escape($script:RIBegin)).Count
    $end = [regex]::Matches($Text,[regex]::Escape($script:RIEnd)).Count
    $pattern = [regex]::Escape($script:RIBegin) + '[\s\S]*?' + [regex]::Escape($script:RIEnd)
    $blocks = [regex]::Matches($Text,$pattern)
    if ($begin -ne $end -or $begin -gt 1 -or $blocks.Count -ne $begin) { throw 'Malformed or duplicate manager markers. Surgical recovery required.' }
    $outside = [regex]::Replace($Text,$pattern,'')
    if ($outside -match '(?i)rasinsider\.css') { throw 'Unmarked prototype CSS reference found. Preserve it and migrate manually; see RECOVERY.md.' }
    if ($begin -eq 1) {
        $block = $blocks[0].Value
        $linkPattern = '(?i)^' + [regex]::Escape($script:RIBegin) + '\s*<link\s+rel="stylesheet"\s+href="/userportal/rasinsider\.css(?:\?v=[0-9a-f]{64})?"\s*>\s*' + [regex]::Escape($script:RIEnd) + '$'
        if ($block -notmatch $linkPattern) { throw 'Managed block contains unexpected content. No automatic deletion.' }
    }
    [PSCustomObject]@{ Count = $begin; Pattern = $pattern }
}

function ConvertTo-RIHook {
    param([Parameter(Mandatory)][byte[]]$Bytes,[switch]$Remove,[string]$CssHash)
    $index = ConvertFrom-RIIndex $Bytes
    $hook = Get-RIHookInfo $index.Text
    $text = $index.Text
    if ($Remove) {
        $text = [regex]::Replace($text,$hook.Pattern,'')
    } else {
        if ($CssHash -cnotmatch '^[0-9a-f]{64}$') { throw 'Invalid CSS hash.' }
        $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
        $block = $script:RIBegin + $newline + '<link rel="stylesheet" href="/userportal/rasinsider.css?v=' + $CssHash + '">' + $newline + $script:RIEnd
        if ($hook.Count -eq 1) { $text = [regex]::Replace($text,$hook.Pattern,[Text.RegularExpressions.MatchEvaluator]{ $block }) }
        else {
            $heads = [regex]::Matches($text,'(?i)</head\s*>')
            if ($heads.Count -ne 1) { throw 'Expected exactly one closing head tag.' }
            $text = $text.Insert($heads[0].Index,$block)
        }
    }
    [byte[]]$output = $index.Bom + $index.Encoding.GetBytes($text)
    return ,$output
}

function Get-RIRequiredProperty {
    param($Object,[string]$Name)
    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) { throw "RAS API contract mismatch: property '$Name' missing. Inspect installed help/types." }
    $Object.$Name
}

function Get-RIInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Server,[PSCredential]$Credential)
    Import-Module RASAdmin -ErrorAction Stop
    $contracts = @{
        'New-RASSession' = @('Server','Username','Password')
        'Remove-RASSession' = @()
        'Get-RASSite' = @()
        'Get-RASGateway' = @('SiteId')
        'Get-RASGatewayStatus' = @('Id')
        'Get-RASVersion' = @()
    }
    foreach ($name in $contracts.Keys) {
        $command = Get-Command $name -Module RASAdmin -ErrorAction Stop
        foreach ($parameter in $contracts[$name]) {
            if (-not $command.Parameters.ContainsKey($parameter)) { throw "Installed RAS API lacks $name -$parameter." }
        }
    }
    if (-not $Credential) { $Credential = Get-Credential -Message 'RAS administrator (UPN); credentials are not saved' }
    if (-not $Credential) { throw 'RAS authentication cancelled.' }
    $connected = $false
    try {
        $null = RASAdmin\New-RASSession -Server $Server -Username $Credential.UserName -Password $Credential.Password -ErrorAction Stop
        $connected = $true
        $version = [string](RASAdmin\Get-RASVersion -ErrorAction Stop)
        $sites = @(RASAdmin\Get-RASSite -ErrorAction Stop)
        $nodes = @()
        foreach ($site in $sites) {
            $sid = [uint32](Get-RIRequiredProperty $site 'Id')
            $siteName = [string](Get-RIRequiredProperty $site 'Name')
            foreach ($gateway in @(RASAdmin\Get-RASGateway -SiteId $sid -ErrorAction Stop)) {
                $id = [uint32](Get-RIRequiredProperty $gateway 'Id')
                $hostName = [string](Get-RIRequiredProperty $gateway 'Server')
                if ($hostName -notmatch '^(?=.{1,253}$)[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$' -and $hostName -notmatch '^[A-Za-z0-9]$') { throw 'Gateway hostname is not safe for WinRM. IPv6 literals are not supported in this preview.' }
                if ([uint32](Get-RIRequiredProperty $gateway 'SiteId') -ne $sid) { throw 'Gateway SiteId mismatch.' }
                $enabled = [bool](Get-RIRequiredProperty $gateway 'Enabled')
                $mode = [string](Get-RIRequiredProperty $gateway 'Mode')
                $status = $null; $statusError = $null
                try { $status = RASAdmin\Get-RASGatewayStatus -Id $id -ErrorAction Stop }
                catch { $statusError = 'RAS gateway status query failed; inspect in RAS Console.' }
                $agentVersion = if ($status) { [string](Get-RIRequiredProperty $status 'AgentVer') } else { '' }
                $agentState = if ($status) { [string](Get-RIRequiredProperty $status 'AgentState') } else { 'Unknown' }
                $nodes += [PSCustomObject]@{
                    Farm = $Server.ToLowerInvariant(); FarmVersion = $version
                    SiteId = $sid; SiteName = $siteName; Id = $id; Server = $hostName
                    Enabled = $enabled; Mode = $mode; AgentVersion = $agentVersion
                    AgentState = $agentState; StatusError = $statusError
                    PortalSetting = if ($gateway.PSObject.Properties['EnableUserPortal']) { $gateway.EnableUserPortal } else { 'Unknown' }
                }
            }
        }
        if (@($nodes | Group-Object Server | Where-Object Count -gt 1).Count -gt 0) { throw 'Duplicate Gateway hosts across inventory. Resolve ambiguity before deployment.' }
        $module = Get-Module RASAdmin
        [PSCustomObject]@{ Farm = $Server.ToLowerInvariant(); Version = $version; Sites = $sites; Gateways = $nodes; ModuleVersion = [string]$module.Version }
    } finally {
        if ($connected) { $null = RASAdmin\Remove-RASSession -ErrorAction Stop }
    }
}

function Test-RIAdministrator {
    if ($env:OS -ne 'Windows_NT') { throw 'Live administration requires Windows.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'An elevated administrator context is required.' }
}

function Assert-RINoReparse {
    param([string]$Path)
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse point rejected: $current" }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
}

function Read-RIFileContent {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return ,([IO.File]::ReadAllBytes($Path)) }
    return $null
}

function Write-RIAtomic {
    param([string]$Path,[byte[]]$Bytes,[string]$ExpectedHash)
    Assert-RINoReparse $Path
    $temp = $Path + '.ri-' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllBytes($temp,$Bytes)
        if ((Get-RIHash (Read-RIFileContent $Path)) -ne $ExpectedHash) { throw "Concurrent change detected: $Path" }
        if ($ExpectedHash -eq 'ABSENT') { [IO.File]::Move($temp,$Path) }
        else {
            # File.Replace preserves the destination ACL on Windows; no unsafe fallback.
            [IO.File]::Replace($temp,$Path,[System.Management.Automation.Language.NullString]::Value)
        }
        if ((Get-RIHash (Read-RIFileContent $Path)) -ne (Get-RIHash $Bytes)) { throw "Write verification failed: $Path" }
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction Stop } }
}

function Write-RIJson {
    param([string]$Path,$Value)
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($Value | ConvertTo-Json -Depth 20))
    Write-RIAtomic $Path $bytes (Get-RIHash (Read-RIFileContent $Path))
}

function Get-RIWorkerPath {
    param($Request)
    $root = [IO.Path]::GetFullPath($Request.PortalRoot)
    $relative = [string]$Request.IndexRelativePath
    if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)' -or $relative -match ':' -or $relative -notmatch '(?i)\.html$') { throw 'Index must be a safe relative .html path inside PortalRoot.' }
    $index = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $index.StartsWith($root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Index escapes portal root.' }
    if (-not $env:ProgramData) { throw 'ProgramData is unavailable.' }
    $stateRoot = Join-Path $env:ProgramData 'RASInsider/RAS-UserPortal-SkinManager'
    $paths = [PSCustomObject]@{
        Root = $root; Index = $index; Css = Join-Path $root 'rasinsider.css'
        StateRoot = $stateRoot; State = Join-Path $stateRoot 'state.json'
        Lock = Join-Path $stateRoot 'active-transaction.json'
        Transactions = Join-Path $stateRoot 'transactions'
    }
    foreach ($path in $root,$index,$paths.Css,$stateRoot,$paths.State,$paths.Lock,$paths.Transactions) { Assert-RINoReparse $path }
    $paths
}

function Get-RIWorkerSnapshot {
    param($Paths,$Request)
    if (-not (Test-Path -LiteralPath $Paths.Root -PathType Container)) { throw 'PortalRoot does not exist. Supply the actual installation path.' }
    $index = Read-RIFileContent $Paths.Index
    if ($null -eq $index) { throw 'Physical portal index not found.' }
    $decoded = ConvertFrom-RIIndex $index
    $hook = Get-RIHookInfo $decoded.Text
    $css = Read-RIFileContent $Paths.Css
    $stateBytes = Read-RIFileContent $Paths.State
    $state = $null
    if ($stateBytes) {
        try { $state = [Text.Encoding]::UTF8.GetString($stateBytes) | ConvertFrom-Json -ErrorAction Stop }
        catch { throw 'Corrupt state.json: preserve files and see RECOVERY.md.' }
        foreach ($p in 'SchemaVersion','Farm','SiteId','GatewayId','PortalRoot','IndexRelativePath','CssHash','IndexHash','Skin','Installed') {
            if ($null -eq $state.PSObject.Properties[$p]) { throw "State schema missing $p." }
        }
        if ($state.SchemaVersion -ne 1 -or $state.Farm -ne $Request.Farm -or $state.SiteId -ne $Request.SiteId -or $state.GatewayId -ne $Request.GatewayId) { throw 'State identity/schema mismatch. Do not adopt another Farm or Gateway state.' }
        if ($state.PortalRoot -ne $Paths.Root -or $state.IndexRelativePath -ne $Request.IndexRelativePath) { throw 'Portal path differs from saved state. Reconcile before deploying.' }
        $null = Test-RISkin $state.Skin
    }
    $cssHash = Get-RIHash $css; $indexHash = Get-RIHash $index
    $health = if ($hook.Count -eq 0 -and $cssHash -eq 'ABSENT' -and (-not $state -or -not $state.Installed)) { 'Original' }
        elseif (-not $state) { 'UnmanagedPrototype' }
        elseif (-not $state.Installed) { 'UnexpectedFiles' }
        elseif ($hook.Count -ne 1) { 'HookMissing' }
        elseif ($cssHash -ne $state.CssHash) { 'CssDrift' }
        elseif ($indexHash -ne $state.IndexHash) { 'IndexDrift' }
        else { 'Healthy' }
    $active = Read-RIFileContent $Paths.Lock
    [PSCustomObject]@{
        Server = $Request.Server; SiteId = $Request.SiteId; GatewayId = $Request.GatewayId
        Build = $Request.AgentVersion; Hook = $hook.Count; CssHash = $cssHash; IndexHash = $indexHash
        StateHash = Get-RIHash $stateBytes; State = $state; Health = $health
        IndexBase64 = [Convert]::ToBase64String($index)
        ActiveTransaction = if ($active) { [Text.Encoding]::UTF8.GetString($active) } else { $null }
        Paths = $Paths
    }
}

function Assert-RILock {
    param($Paths,[string]$TransactionId)
    $lockBytes = Read-RIFileContent $Paths.Lock
    if (-not $lockBytes) { throw 'Transaction lock is missing. Stop and reconcile.' }
    $lock = [Text.Encoding]::UTF8.GetString($lockBytes) | ConvertFrom-Json -ErrorAction Stop
    if ($lock.TransactionId -ne $TransactionId) { throw 'Gateway is locked by another transaction.' }
}

function Invoke-RIWorker {
    [CmdletBinding()]
    param([ValidateSet('Inspect','Preflight','Prepare','Commit','Verify','Rollback','Finalize')][string]$Operation,[Parameter(Mandatory)]$Request)
    Test-RIAdministrator
    $paths = Get-RIWorkerPath $Request
    if ($Operation -eq 'Inspect') { return Get-RIWorkerSnapshot $paths $Request }
    if ($Operation -eq 'Preflight') {
        $snapshot = Get-RIWorkerSnapshot $paths $Request
        if ($snapshot.ActiveTransaction) { throw 'Interrupted/active transaction found; recover it first.' }
        $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($paths.Root))
        if ($drive.AvailableFreeSpace -lt 10485760) { throw 'Less than 10 MiB free on the portal volume.' }
        $stateDrive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($paths.StateRoot))
        if ($stateDrive.AvailableFreeSpace -lt 10485760) { throw 'Less than 10 MiB free on the ProgramData volume.' }
        # Only capability probes and manager state directories are touched in pre-flight.
        $null = [IO.Directory]::CreateDirectory($paths.StateRoot)
        foreach ($directory in @($paths.Root,[IO.Path]::GetDirectoryName($paths.Index),$paths.StateRoot) | Select-Object -Unique) {
            $probe = Join-Path $directory ('.ri-probe-' + [guid]::NewGuid().ToString('N'))
            try {
                $stream = [IO.File]::Open($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
                $stream.Dispose()
            } finally { if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force -ErrorAction Stop } }
        }
        return $snapshot
    }
    if ($Request.TransactionId -cnotmatch '^[0-9a-f]{32}$') { throw 'Invalid transaction ID.' }
    $transaction = Join-Path $paths.Transactions $Request.TransactionId
    Assert-RINoReparse $transaction
    $manifestPath = Join-Path $transaction 'manifest.json'
    if ($Operation -eq 'Prepare') {
        $snapshot = Get-RIWorkerSnapshot $paths $Request
        if ($snapshot.ActiveTransaction) { throw 'Another transaction owns this Gateway.' }
        foreach ($field in 'IndexHash','CssHash','StateHash') {
            if ($snapshot.$field -ne $Request.Expected.$field) { throw "Concurrent drift before preparation: $field" }
        }
        $lockStream = [IO.File]::Open($paths.Lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try {
            $lockBytes = [Text.Encoding]::UTF8.GetBytes((@{ TransactionId = $Request.TransactionId; StartedUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json))
            $lockStream.Write($lockBytes,0,$lockBytes.Length); $lockStream.Flush()
        } finally { $lockStream.Dispose() }
        try {
            $null = [IO.Directory]::CreateDirectory($transaction)
            $manifest = [ordered]@{ TransactionId = $Request.TransactionId; Phase = 'Prepared'; Files = @() }
            foreach ($name in 'Css','Index','State') {
                $path = $paths.$name
                $old = Read-RIFileContent $path
                $oldHash = Get-RIHash $old
                $hashProperty = $name + 'Hash'
                if ($oldHash -ne $Request.Expected.$hashProperty) { throw 'Concurrent change during snapshot creation.' }
                if ($null -ne $old) { [IO.File]::WriteAllBytes((Join-Path $transaction ($name + '.before')),$old) }
                $value = $Request.Desired.$name
                $newBytes = if ($null -ne $value) { [Convert]::FromBase64String([string]$value) } else { $null }
                if ($null -ne $newBytes) { [IO.File]::WriteAllBytes((Join-Path $transaction ($name + '.after')),$newBytes) }
                $manifest.Files += [PSCustomObject]@{ Name = $name; Path = $path; Before = $oldHash; After = Get-RIHash $newBytes; Changed = $false }
            }
            # Restore detaches index before removing CSS; install writes CSS before hook.
            if ($Request.Action -eq 'Restore') { $manifest.Files = @($manifest.Files | Sort-Object @{Expression={ if ($_.Name -eq 'Index') { 0 } elseif ($_.Name -eq 'Css') { 1 } else { 2 } }}) }
            Write-RIJson $manifestPath $manifest
            return [PSCustomObject]@{ Phase = 'Prepared'; TransactionId = $Request.TransactionId }
        } catch {
            # No live file has changed. Release only our own lock; keep snapshots for inspection.
            Assert-RILock $paths $Request.TransactionId
            Remove-Item -LiteralPath $paths.Lock -Force -ErrorAction Stop
            throw
        }
    }
    Assert-RILock $paths $Request.TransactionId
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Transaction manifest missing. Manual recovery required.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($manifest.TransactionId -ne $Request.TransactionId) { throw 'Transaction manifest identity mismatch.' }
    foreach ($file in $manifest.Files) {
        if ($file.Name -notin @('Index','Css','State') -or $file.Path -ne $paths.($file.Name)) { throw 'Unsafe transaction file entry.' }
    }
    switch ($Operation) {
        'Commit' {
            foreach ($file in $manifest.Files) {
                if ((Get-RIHash (Read-RIFileContent $file.Path)) -ne $file.Before) { throw "Concurrent drift before commit: $($file.Name)" }
                if ($file.After -ne 'ABSENT' -and (Get-RIHash (Read-RIFileContent (Join-Path $transaction ($file.Name + '.after')))) -ne $file.After) { throw 'Staged file hash mismatch.' }
            }
            $manifest.Phase = 'Committing'; Write-RIJson $manifestPath $manifest
            foreach ($file in $manifest.Files) {
                if ($file.Before -eq $file.After) { continue }
                # Persist intent first: crash recovery evaluates hashes, never assumes success.
                $file.Changed = $true; Write-RIJson $manifestPath $manifest
                if ($file.After -eq 'ABSENT') {
                    if ((Get-RIHash (Read-RIFileContent $file.Path)) -ne $file.Before) { throw 'Concurrent change before deletion.' }
                    Remove-Item -LiteralPath $file.Path -Force -ErrorAction Stop
                } else {
                    Write-RIAtomic $file.Path (Read-RIFileContent (Join-Path $transaction ($file.Name + '.after'))) $file.Before
                }
            }
            $manifest.Phase = 'Committed'; Write-RIJson $manifestPath $manifest
            [PSCustomObject]@{ Phase = 'Committed'; TransactionId = $Request.TransactionId }
        }
        'Verify' {
            foreach ($file in $manifest.Files) {
                if ((Get-RIHash (Read-RIFileContent $file.Path)) -ne $file.After) { throw "Post-deployment verification failed: $($file.Name)" }
            }
            $manifest.Phase = 'Verified'; Write-RIJson $manifestPath $manifest
            Get-RIWorkerSnapshot $paths $Request
        }
        'Rollback' {
            # Validate ALL affected current files and backups before rolling back ANY.
            foreach ($file in $manifest.Files) {
                $actual = Get-RIHash (Read-RIFileContent $file.Path)
                if ($actual -ne $file.Before -and $actual -ne $file.After) { throw "Rollback refused: unrelated concurrent edit/upgrade in $($file.Name). Surgical recovery required." }
                if ($file.Before -ne 'ABSENT' -and (Get-RIHash (Read-RIFileContent (Join-Path $transaction ($file.Name + '.before')))) -ne $file.Before) { throw 'Rollback snapshot corrupt/missing.' }
            }
            $manifest.Phase = 'RollingBack'; Write-RIJson $manifestPath $manifest
            # Restore dependency order: original CSS first if it existed, then index, then state.
            $ordered = @($manifest.Files | Sort-Object @{Expression={ if ($_.Name -eq 'Css' -and $_.Before -ne 'ABSENT') { 0 } elseif ($_.Name -eq 'Index') { 1 } elseif ($_.Name -eq 'Css') { 2 } else { 3 } }})
            foreach ($file in $ordered) {
                $actual = Get-RIHash (Read-RIFileContent $file.Path)
                if ($actual -eq $file.Before) { continue }
                if ($actual -ne $file.After) { throw 'Concurrent change during rollback.' }
                if ($file.Before -eq 'ABSENT') { Remove-Item -LiteralPath $file.Path -Force -ErrorAction Stop }
                else { Write-RIAtomic $file.Path (Read-RIFileContent (Join-Path $transaction ($file.Name + '.before'))) $actual }
                if ((Get-RIHash (Read-RIFileContent $file.Path)) -ne $file.Before) { throw 'Rollback verification failed.' }
            }
            $manifest.Phase = 'RolledBack'; Write-RIJson $manifestPath $manifest
            [PSCustomObject]@{ Phase = 'RolledBack'; TransactionId = $Request.TransactionId }
        }
        'Finalize' {
            if ($manifest.Phase -notin 'Verified','RolledBack') { throw 'Cannot finalize an unverified transaction.' }
            $hashField = if ($manifest.Phase -eq 'Verified') { 'After' } else { 'Before' }
            foreach ($file in $manifest.Files) {
                if ((Get-RIHash (Read-RIFileContent $file.Path)) -ne $file.$hashField) { throw 'Concurrent change before finalization.' }
            }
            Remove-Item -LiteralPath $paths.Lock -Force -ErrorAction Stop
            [PSCustomObject]@{ Phase = $manifest.Phase; TransactionId = $Request.TransactionId }
        }
    }
}

# Serialize our own function definitions; no external runtime scripts are required.
$script:RIWorkerSource = '$script:RIBegin = ''<!-- RASINSIDER-SKIN-MANAGER:BEGIN -->''; $script:RIEnd = ''<!-- RASINSIDER-SKIN-MANAGER:END -->'';' + "`n"
foreach ($functionName in 'Get-RIPreset','Test-RISkin','Get-RIHash','ConvertFrom-RIIndex','Get-RIHookInfo','Test-RIAdministrator','Assert-RINoReparse','Read-RIFileContent','Write-RIAtomic','Write-RIJson','Get-RIWorkerPath','Get-RIWorkerSnapshot','Assert-RILock','Invoke-RIWorker') {
    $script:RIWorkerSource += 'function ' + $functionName + ' {' + (Get-Command $functionName -CommandType Function).Definition + "}`n"
}
$script:RIRemoteWorker = [scriptblock]::Create('param($Operation,$Request)' + "`n" + $script:RIWorkerSource + "`n" + 'Invoke-RIWorker -Operation $Operation -Request $Request')

function Invoke-RITarget {
    param($Target,[string]$Operation,$Request)
    Invoke-Command -Session $Target.Session -ScriptBlock $script:RIRemoteWorker -ArgumentList $Operation,$Request -ErrorAction Stop
}

function Get-RIRequest {
    param($Node,[string]$Root,[string]$RelativePath)
    [PSCustomObject]@{
        Farm = $Node.Farm; SiteId = $Node.SiteId; GatewayId = $Node.Id; Server = $Node.Server
        AgentVersion = $Node.AgentVersion; PortalRoot = $Root; IndexRelativePath = $RelativePath
        TransactionId = $null; Expected = $null; Desired = $null; Action = $null
    }
}

function Get-RIPlan {
    param($Snapshot,$Request,[string]$Operation,$Skin,[switch]$DriftAccepted,[switch]$PrototypeAdopted)
    if ($Snapshot.ActiveTransaction) { throw 'Pending transaction must be recovered first.' }
    $oldState = $Snapshot.State
    if ($Snapshot.Health -eq 'UnmanagedPrototype' -and -not $PrototypeAdopted) { throw 'Existing CSS/marked prototype is unmanaged. Archive and use -AdoptPrototype only after review.' }
    if (($Snapshot.Health -in 'CssDrift','IndexDrift','UnexpectedFiles' -or ($oldState -and $oldState.Installed -and $Snapshot.CssHash -ne $oldState.CssHash)) -and -not $DriftAccepted) { throw 'Drift detected. Review and use -AcceptDrift to reconcile current files.' }
    if ($Operation -eq 'Reapply') {
        if (-not $oldState -or -not $oldState.Installed) { throw 'No installed skin configuration to re-apply.' }
        $Skin = $oldState.Skin
    }
    if ($Operation -eq 'Restore' -and -not $oldState -and ($Snapshot.CssHash -ne 'ABSENT' -or $Snapshot.Hook -gt 0)) { throw 'Restore cannot delete unowned prototype files. Migrate first.' }
    $originalIndex = [Convert]::FromBase64String($Snapshot.IndexBase64)
    $utf8 = New-Object Text.UTF8Encoding($false)
    if ($Operation -eq 'Restore') {
        $index = ConvertTo-RIHook $originalIndex -Remove
        $css = $null; $cssHash = 'ABSENT'
        $savedSkin = if ($oldState) { $oldState.Skin } else { Get-RIPreset }
    } else {
        $null = Test-RISkin $Skin
        $css = $utf8.GetBytes((Get-RICss $Skin)); $cssHash = Get-RIHash $css
        $index = ConvertTo-RIHook $originalIndex -CssHash $cssHash; $savedSkin = $Skin
    }
    # No-op install/re-apply leaves state timestamps and file hashes unchanged.
    if ($oldState -and $Snapshot.CssHash -eq $cssHash -and $Snapshot.IndexHash -eq (Get-RIHash $index) -and $oldState.Installed -eq ($Operation -ne 'Restore') -and ($oldState.Skin | ConvertTo-Json -Compress) -eq ($savedSkin | ConvertTo-Json -Compress)) {
        return [PSCustomObject]@{ NoChange = $true; Request = $Request }
    }
    if ($Operation -eq 'Restore' -and -not $oldState -and $Snapshot.CssHash -eq 'ABSENT' -and $Snapshot.Hook -eq 0) { return [PSCustomObject]@{ NoChange = $true; Request = $Request } }
    $state = [ordered]@{
        SchemaVersion = 1; ManagerVersion = $script:RIVersion; Farm = $Request.Farm
        SiteId = $Request.SiteId; GatewayId = $Request.GatewayId; Server = $Request.Server
        PortalRoot = $Snapshot.Paths.Root; IndexRelativePath = $Request.IndexRelativePath
        ProductVersion = $Request.AgentVersion; Skin = $savedSkin; CssHash = $cssHash
        IndexHash = Get-RIHash $index; Installed = ($Operation -ne 'Restore')
        UpdatedUtc = [DateTime]::UtcNow.ToString('o')
    }
    $Request.Expected = [PSCustomObject]@{ IndexHash = $Snapshot.IndexHash; CssHash = $Snapshot.CssHash; StateHash = $Snapshot.StateHash }
    $Request.Desired = [PSCustomObject]@{
        Index = [Convert]::ToBase64String($index)
        Css = if ($null -ne $css) { [Convert]::ToBase64String($css) } else { $null }
        State = [Convert]::ToBase64String($utf8.GetBytes(($state | ConvertTo-Json -Depth 12)))
    }
    $Request.Action = $Operation
    [PSCustomObject]@{ NoChange = $false; Request = $Request }
}

function Write-RILog {
    param([string]$Path,[string]$TransactionId,[string]$EventName,[string]$Server = '')
    $entry = @{ Utc = [DateTime]::UtcNow.ToString('o'); TransactionId = $TransactionId; Event = $EventName; Server = $Server } | ConvertTo-Json -Compress
    [IO.File]::AppendAllText($Path,$entry + [Environment]::NewLine,(New-Object Text.UTF8Encoding($false)))
}

function Invoke-RIRollbackTarget {
    param([array]$Targets,$Journal,[string]$JournalPath,[string]$LogPath)
    $failed = @()
    foreach ($target in $Targets) {
        try {
            $inspection = Invoke-RITarget $target 'Inspect' $target.Request
            if ($inspection.ActiveTransaction) {
                $lock = $inspection.ActiveTransaction | ConvertFrom-Json -ErrorAction Stop
                if ($lock.TransactionId -ne $Journal.TransactionId) { throw 'Another transaction owns this target.' }
                $null = Invoke-RITarget $target 'Rollback' $target.Request
                $null = Invoke-RITarget $target 'Finalize' $target.Request
            } else {
                # An already finalized/recovered target must match its pre-transaction state.
                foreach ($field in 'IndexHash','CssHash','StateHash') {
                    if ($inspection.$field -ne $target.Request.Expected.$field) { throw 'Unlocked target no longer matches rollback baseline.' }
                }
            }
            Write-RILog $LogPath $Journal.TransactionId 'RollbackVerified' $target.Node.Server
        } catch {
            $failed += $target.Node.Server
            Write-RILog $LogPath $Journal.TransactionId 'RollbackFailed_ManualRecoveryRequired' $target.Node.Server
            Write-Warning "Rollback not verified on $($target.Node.Server): $($_.Exception.Message)"
        }
    }
    $Journal.Phase = if ($failed.Count) { 'RecoveryRequired' } else { 'RolledBack' }
    $Journal.FailedTargets = $failed
    Write-RIJson $JournalPath $Journal
    return ,$failed
}

function Invoke-RIDeployment {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$Targets,[string]$Operation,$Skin,[string]$CoordinatorRoot,[switch]$DriftAccepted,[switch]$PrototypeAdopted)
    $preflightErrors = @(); $plans = @()
    # Every selected node is evaluated. No live write is performed in this loop.
    foreach ($target in $Targets) {
        try {
            $snapshot = Invoke-RITarget $target 'Preflight' $target.Request
            $plan = Get-RIPlan $snapshot $target.Request $Operation $Skin -DriftAccepted:$DriftAccepted -PrototypeAdopted:$PrototypeAdopted
            $target.Request = $plan.Request
            $target | Add-Member -NotePropertyName NoChange -NotePropertyValue $plan.NoChange -Force
            $target | Add-Member -NotePropertyName Preflight -NotePropertyValue $snapshot -Force
            $plans += $target
            Write-Host "[OK] Pre-flight: $($target.Node.Server) ($($snapshot.Health))"
        } catch {
            $preflightErrors += "$($target.Node.Server): $($_.Exception.Message)"
            Write-Warning $preflightErrors[-1]
        }
    }
    if ($preflightErrors.Count) { throw 'Pre-flight aborted. No live portal files on any Gateway were modified.' }
    $changed = @($plans | Where-Object { -not $_.NoChange })
    if (-not $changed.Count) { Write-Host 'All selected Gateways already match the requested configuration.'; return }
    $id = [guid]::NewGuid().ToString('N')
    $null = [IO.Directory]::CreateDirectory($CoordinatorRoot)
    $journalPath = Join-Path $CoordinatorRoot ($id + '.json')
    $logPath = Join-Path $CoordinatorRoot 'events.jsonl'
    $journal = [PSCustomObject]@{
        SchemaVersion = 1; TransactionId = $id; Phase = 'Preparing'; Operation = $Operation
        StartedUtc = [DateTime]::UtcNow.ToString('o'); Targets = @(); FailedTargets = @()
    }
    foreach ($target in $changed) {
        $target.Request.TransactionId = $id
        $journal.Targets += [PSCustomObject]@{ Node = $target.Node; Request = $target.Request }
    }
    Write-RIJson $journalPath $journal
    Write-Host "Transaction: $id"
    $attempted = @()
    $committedAll = $false
    try {
        foreach ($target in $changed) {
            # Include a target before dispatch: a lost remote response may hide preparation.
            $attempted += $target
            $null = Invoke-RITarget $target 'Prepare' $target.Request
            Write-RILog $logPath $id 'Prepared' $target.Node.Server
        }
        $journal.Phase = 'Committing'; Write-RIJson $journalPath $journal
        foreach ($target in $changed) {
            $null = Invoke-RITarget $target 'Commit' $target.Request
            Write-RILog $logPath $id 'Committed' $target.Node.Server
        }
        foreach ($target in $changed) {
            $verified = Invoke-RITarget $target 'Verify' $target.Request
            if ($Operation -ne 'Restore' -and $verified.Health -ne 'Healthy') { throw 'Gateway verification is not healthy.' }
            if ($Operation -eq 'Restore' -and $verified.Health -ne 'Original') { throw 'Restore verification failed.' }
            Write-RILog $logPath $id 'Verified' $target.Node.Server
        }
        foreach ($target in @($plans | Where-Object NoChange)) {
            $current = Invoke-RITarget $target 'Inspect' $target.Request
            foreach ($field in 'IndexHash','CssHash','StateHash') {
                if ($current.$field -ne $target.Preflight.$field) { throw 'An unchanged selected target drifted during rollout.' }
            }
        }
        $journal.Phase = 'Verified'; Write-RIJson $journalPath $journal
        $committedAll = $true
    } catch {
        Write-RILog $logPath $id 'DeploymentFailed' ''
        Write-Warning "Deployment failed: $($_.Exception.Message)"
        $failed = Invoke-RIRollbackTarget $attempted $journal $journalPath $logPath
        if ($failed.Count) { throw "Recovery required for: $($failed -join ', '). Transaction $id. See RECOVERY.md." }
        throw "Deployment failed; rollback verified on attempted targets. Transaction $id."
    }
    if ($committedAll) {
        $finalizeErrors = @()
        foreach ($target in $changed) {
            try { $null = Invoke-RITarget $target 'Finalize' $target.Request }
            catch { $finalizeErrors += $target.Node.Server; Write-Warning "Finalization requires recovery on $($target.Node.Server)." }
        }
        $journal.Phase = if ($finalizeErrors.Count) { 'FinalizationRequired' } else { 'Completed' }
        $journal.FailedTargets = $finalizeErrors; Write-RIJson $journalPath $journal
        if ($finalizeErrors.Count) { throw "All deployed files verified, but locks require finalization. Use -RecoverTransaction $id; see RECOVERY.md." }
        Write-Host "Deployment successful: $($Targets.Count) / $($Targets.Count) selected Gateways verified."
    }
}

function Read-RICustomSkin {
    $skin = Get-RIPreset 'Custom'
    foreach ($p in 'Header','PanelStart','PanelMiddle','PanelEnd','Accent','Border','Primary') {
        $value = Read-Host "$p (#RRGGBB; Enter keeps $($skin.$p))"
        if ($value) { $skin.$p = $value }
    }
    foreach ($p in 'HeaderOpacity','StartOpacity','MiddleOpacity','EndOpacity','SecondaryOpacity','MutedOpacity','Blur','Radius') {
        $value = Read-Host "$p (Enter keeps $($skin.$p); use decimal point)"
        if ($value) {
            $n = 0.0
            if (-not [double]::TryParse($value,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$n)) { throw "Invalid number: $p" }
            $skin.$p = $n
        }
    }
    $null = Test-RISkin $skin
    $skin
}

function Select-RIScope {
    param($Inventory,[uint32[]]$Sites,[uint32[]]$Gateways,[switch]$EverySite,[switch]$Interactive)
    if ($EverySite -and ($Sites.Count -gt 0 -or $Gateways.Count -gt 0)) { throw 'Choose AllSites or explicit IDs, not both.' }
    if ($Interactive -and -not $EverySite -and -not $Sites.Count -and -not $Gateways.Count) {
        $Inventory.Gateways | Select-Object SiteId,SiteName,Id,Server,Enabled,Mode,AgentVersion,AgentState | Format-Table -AutoSize | Out-Host
        Write-Host 'Scope: A = all Sites; S:1,2 = Sites; G:10,11 = discovered Gateway IDs'
        $choice = Read-Host 'Select scope'
        if ($choice -eq 'A') { $EverySite = $true }
        elseif ($choice -match '^[sS]:([0-9]+(?:,[0-9]+)*)$') { $Sites = [uint32[]]($Matches[1] -split ',') }
        elseif ($choice -match '^[gG]:([0-9]+(?:,[0-9]+)*)$') { $Gateways = [uint32[]]($Matches[1] -split ',') }
        else { throw 'Invalid scope.' }
    }
    if (-not $EverySite -and -not $Sites.Count -and -not $Gateways.Count) { throw 'Specify -AllSites, -SiteId or -GatewayId. No implicit target selection.' }
    foreach ($id in $Sites) { if ($id -notin @($Inventory.Sites | ForEach-Object { $_.Id })) { throw "Unknown Site ID: $id" } }
    foreach ($id in $Gateways) { if ($id -notin @($Inventory.Gateways | ForEach-Object { $_.Id })) { throw "Unknown Gateway ID: $id" } }
    $selected = @($Inventory.Gateways | Where-Object {
        $EverySite -or ((-not $Sites.Count -or $_.SiteId -in $Sites) -and (-not $Gateways.Count -or $_.Id -in $Gateways))
    })
    if (-not $selected.Count) { throw 'No Gateways in selected scope.' }
    if ($selected.Count -lt $Inventory.Gateways.Count) { Write-Warning 'Partial Farm scope. Verify shared HALB pools are covered; pool membership is not inferred.' }
    return ,$selected
}

function Invoke-RIMain {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($Caller)
    Test-RIAdministrator
    if (-not $LicensingServer) { $LicensingServer = Read-Host 'RAS Licensing Server (FQDN)' }
    if (-not $LicensingServer) { throw 'Licensing Server is required.' }
    $coordinator = Join-Path $env:ProgramData 'RASInsider/RAS-UserPortal-SkinManager/coordinator'
    Assert-RINoReparse $coordinator
    $interactive = $Action -eq 'Interactive'
    do {
        $operation = $Action
        if ($interactive) {
            Write-Host "`nRASInsider RAS User Portal Skin Manager $script:RIVersion"
            Write-Host 'Independent, unsupported community preview. Allowed: RAS 21.2.x and 22.0 TP build 28102. RAS 21.2.x deployment validation pending.'
            Write-Host '[1] Install / Change skin'
            Write-Host '[2] Re-apply current skin'
            Write-Host '[3] Restore Original'
            Write-Host '[4] Status'
            Write-Host '[5] Exit'
            $choice = Read-Host 'Action'
            switch ($choice) { '1' { $operation = 'Install' } '2' { $operation = 'Reapply' } '3' { $operation = 'Restore' } '4' { $operation = 'Status' } '5' { return } default { Write-Warning 'Invalid action.'; continue } }
        }
        $inventory = Get-RIInventory -Server $LicensingServer -Credential $RASCredential
        Write-Host "Farm connection: $($inventory.Farm) | RAS: $($inventory.Version) | RASAdmin: $($inventory.ModuleVersion)"
        $recovery = $null
        if ($RecoverTransaction) {
            if ($RecoverTransaction -cnotmatch '^[0-9a-f]{32}$') { throw 'Recovery transaction ID must be 32 lowercase hex characters.' }
            $recoveryPath = Join-Path $coordinator ($RecoverTransaction + '.json')
            Assert-RINoReparse $recoveryPath
            $recovery = Get-Content -LiteralPath $recoveryPath -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($recovery.SchemaVersion -ne 1 -or $recovery.TransactionId -ne $RecoverTransaction) { throw 'Invalid recovery journal.' }
            if ($recovery.Phase -in 'Completed','RolledBack') { Write-Host 'Transaction already finalized.'; return }
            $selected = @()
            foreach ($entry in $recovery.Targets) {
                $match = @($inventory.Gateways | Where-Object { $_.Id -eq $entry.Node.Id -and $_.SiteId -eq $entry.Node.SiteId -and $_.Farm -eq $entry.Node.Farm -and $_.Server -eq $entry.Node.Server })
                if ($match.Count -ne 1) { throw 'Recovery target identity no longer matches RAS inventory. Use documented manual recovery.' }
                $selected += $match[0]
            }
        } else { $selected = Select-RIScope $inventory $SiteId $GatewayId -EverySite:$AllSites -Interactive:$interactive }
        $selected | Select-Object SiteName,Id,Server,AgentVersion,AgentState | Format-Table -AutoSize | Out-Host
        $modifying = $operation -ne 'Status' -or $null -ne $recovery
        if ($modifying -and -not $recovery) {
            if (-not $MappingValidated) { throw 'Validate physical PortalRoot/index mapping to /userportal/ in your lab, then use -MappingValidated. No deployment attempted.' }
            foreach ($node in $selected) {
                if (-not $node.Enabled -or $node.Mode -ne 'Normal' -or $node.StatusError -or $node.AgentState -ne 'OK') { throw "Gateway is not an enabled, healthy Normal-mode target: $($node.Server). No portal changes." }
                if (-not (Test-RIAllowedVersion $node.AgentVersion)) {
                    if (-not $AllowUnverifiedBuild) { throw "Version outside the allowed baseline on $($node.Server): $($node.AgentVersion). Use -AllowUnverifiedBuild only for an explicitly reviewed lab." }
                    Write-Warning "Unverified RAS build: $($node.Server) $($node.AgentVersion)"
                }
            }
        }
        $skin = $null
        if ($operation -eq 'Install') {
            if ($SkinFile) {
                $skin = Get-Content -LiteralPath $SkinFile -Raw | ConvertFrom-Json -ErrorAction Stop
                $null = Test-RISkin $skin
            } elseif ($interactive) {
                Write-Host 'Skins:'
                Write-Host ' [1] Dark Glass     [2] Midnight Blue  [3] Light Glass   [4] RASInsider'
                Write-Host ' [5] Custom         [6] Graphite       [7] Forest        [8] Warm Ivory'
                Write-Host ' [9] Bordeaux      [10] Aubergine     [11] Liquid Glass [12] Ruby'
                $skinChoice = Read-Host 'Skin'
                switch ($skinChoice) {
                    '1' { $skin = Get-RIPreset 'Dark Glass' } '2' { $skin = Get-RIPreset 'Midnight Blue' }
                    '3' { $skin = Get-RIPreset 'Light Glass' } '4' { $skin = Get-RIPreset 'RASInsider' }
                    '5' { $skin = Read-RICustomSkin }
                    '6' { $skin = Get-RIPreset 'Graphite' } '7' { $skin = Get-RIPreset 'Forest' }
                    '8' { $skin = Get-RIPreset 'Warm Ivory' } '9' { $skin = Get-RIPreset 'Bordeaux' }
                    '10' { $skin = Get-RIPreset 'Aubergine' } '11' { $skin = Get-RIPreset 'Liquid Glass' }
                    '12' { $skin = Get-RIPreset 'Ruby' } default { throw 'Invalid skin selection.' }
                }
            } else {
                if ($Preset -eq 'Custom') { throw 'Non-interactive Custom requires -SkinFile.' }
                $skin = Get-RIPreset $Preset
            }
            $skin | Format-List | Out-Host
        }
        $targets = @(); $runLock = $null
        try {
            foreach ($node in $selected) {
                $sessionArgs = @{ ComputerName = $node.Server; Authentication = 'Negotiate'; ErrorAction = 'Stop' }
                if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
                if ($UseSSL) { $sessionArgs.UseSSL = $true }
                if ($RemotePort) { $sessionArgs.Port = $RemotePort }
                try { $session = New-PSSession @sessionArgs }
                catch {
                    if ($modifying) { throw "WinRM unavailable on $($node.Server). No deployment attempted." }
                    $session = $null
                }
                $request = Get-RIRequest $node $PortalRoot $IndexRelativePath
                if ($recovery) { $request = @($recovery.Targets | Where-Object { $_.Node.Id -eq $node.Id -and $_.Node.SiteId -eq $node.SiteId })[0].Request }
                $targets += [PSCustomObject]@{ Node = $node; Session = $session; Request = $request }
            }
            if (-not $modifying) {
                $rows = foreach ($target in $targets) {
                    try {
                        $s = Invoke-RITarget $target 'Inspect' $target.Request
                        [PSCustomObject]@{ Gateway = $target.Node.Server; Build = $s.Build; Hook = $s.Hook; CSS = $s.CssHash; Skin = if ($s.State) { $s.State.Skin.Name } else { '-' }; Health = $s.Health; Recovery = [bool]$s.ActiveTransaction }
                    } catch { [PSCustomObject]@{ Gateway = $target.Node.Server; Health = 'InspectionFailed'; Detail = $_.Exception.Message } }
                }
                $rows | Format-Table -AutoSize | Out-Host
                if (@($rows | Where-Object Health -eq 'InspectionFailed').Count) { throw 'Status incomplete: one or more Gateways could not be inspected.' }
            } else {
                # Read-only preview, including WhatIf. No probes, locks or backups yet.
                foreach ($target in $targets) {
                    $snapshot = Invoke-RITarget $target 'Inspect' $target.Request
                    Write-Host "$($target.Node.Server): $($snapshot.Health) | Hook $($snapshot.Hook) | CSS $($snapshot.CssHash)"
                    if (-not $recovery) {
                        $plan = Get-RIPlan $snapshot $target.Request $operation $skin -DriftAccepted:$AcceptDrift -PrototypeAdopted:$AdoptPrototype
                        $target.Request = $plan.Request
                    }
                }
                $verb = if ($recovery) { "Recover transaction $RecoverTransaction" } else { "$operation skin" }
                if ($Caller.ShouldProcess(($selected.Server -join ', '),$verb)) {
                    $null = [IO.Directory]::CreateDirectory($coordinator)
                    $runLock = [IO.File]::Open((Join-Path $coordinator 'run.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
                    if ($recovery) {
                        if ($recovery.Phase -in 'Verified','FinalizationRequired') {
                            foreach ($target in $targets) {
                                $s = Invoke-RITarget $target 'Inspect' $target.Request
                                # If an earlier Finalize succeeded, verify desired hashes rather than reacquiring a lock.
                                foreach ($name in 'Index','Css','State') {
                                    $value = $target.Request.Desired.$name
                                    $bytes = if ($null -ne $value) { [Convert]::FromBase64String($value) } else { $null }
                                    $hashProperty = $name + 'Hash'
                                    if ($s.$hashProperty -ne (Get-RIHash $bytes)) { throw 'Finalization recovery found drift; use surgical recovery.' }
                                }
                                if ($s.ActiveTransaction) { $null = Invoke-RITarget $target 'Finalize' $target.Request }
                            }
                            $recovery.Phase = 'Completed'; Write-RIJson $recoveryPath $recovery
                            Write-Host 'Verified transaction finalized.'
                        } else {
                            $failed = Invoke-RIRollbackTarget $targets $recovery $recoveryPath (Join-Path $coordinator 'events.jsonl')
                            if ($failed.Count) { throw 'Recovery incomplete; see per-target report.' }
                            Write-Host 'Interrupted transaction rolled back and verified.'
                        }
                    } else { Invoke-RIDeployment $targets $operation $skin $coordinator -DriftAccepted:$AcceptDrift -PrototypeAdopted:$AdoptPrototype }
                }
            }
        } finally {
            if ($runLock) { $runLock.Dispose() }
            foreach ($target in $targets) { if ($target.Session) { Remove-PSSession -Session $target.Session -ErrorAction SilentlyContinue } }
        }
        if ($recovery) { return }
    } while ($interactive)
}

# Dot-sourcing loads testable functions without prompting or contacting a Farm.
if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = 'Stop'
    try { Invoke-RIMain $PSCmdlet; exit 0 }
    catch { Write-Error $_ -ErrorAction Continue; exit 1 }
}
