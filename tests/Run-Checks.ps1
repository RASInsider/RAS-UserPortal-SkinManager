#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$scriptPath = Join-Path $root 'RAS-UserPortal-SkinManager.ps1'
$errors = $null; $tokens = $null
$null = [Management.Automation.Language.Parser]::ParseFile($scriptPath,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
. $scriptPath
# Filesystem fixtures only. No network/Windows/RAS calls; production worker still enforces elevation.
function Test-RIAdministrator { }
$script:passed = 0
function Assert-Check {
    param([bool]$Condition,[string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++; Write-Host "PASS: $Name"
}
function Assert-Throws {
    param([scriptblock]$Body,[string]$Name)
    $thrown = $false
    try { $null = & $Body } catch { $thrown = $true }
    Assert-Check $thrown $Name
}
$fixture = Join-Path $root ('ri-tests-' + [guid]::NewGuid().ToString('N'))
$previousProgramData = $env:ProgramData
try {
    $null = [IO.Directory]::CreateDirectory($fixture)
    foreach ($name in 'Dark Glass','Midnight Blue','Light Glass','RASInsider','Custom') {
        $css = Get-RICss (Get-RIPreset $name)
        Assert-Check ($css -match '--ri-' -and $css -notmatch 'data-v-' -and $css -notmatch 'url\(') "Embedded preset: $name"
    }
    $skin = Get-RIPreset; $skin.Accent = '#fff; background:url(https://bad)'
    Assert-Throws { Test-RISkin $skin } 'Reject CSS injection'
    $skin = Get-RIPreset; $skin.Blur = [double]::NaN
    Assert-Throws { Test-RISkin $skin } 'Reject non-finite value'
    $skin.Blur = 61
    Assert-Throws { Test-RISkin $skin } 'Reject excessive blur'
    $skin = Get-RIPreset; $skin.HeaderOpacity = '0.8'
    Assert-Throws { Test-RISkin $skin } 'Reject string-valued opacity'
    $skin = Get-RIPreset; $skin | Add-Member Evil 'red'
    Assert-Throws { Test-RISkin $skin } 'Reject unknown schema property'
    $skin = Get-RIPreset
    $invariant = Get-RICss $skin
    $oldCulture = [Threading.Thread]::CurrentThread.CurrentCulture
    try {
        [Threading.Thread]::CurrentThread.CurrentCulture = 'fr-FR'
        Assert-Check ((Get-RICss $skin) -ceq $invariant) 'CSS is invariant across decimal cultures'
    } finally { [Threading.Thread]::CurrentThread.CurrentCulture = $oldCulture }
    $hash = Get-RIHash ([Text.Encoding]::UTF8.GetBytes($invariant))
    $original = [Text.Encoding]::UTF8.GetBytes("<!doctype html>`r`n<html><head><link href='/assets/vendor.css'></head><body>Theme</body></html>")
    $installed = ConvertTo-RIHook $original -CssHash $hash
    Assert-Check ((Get-RIHookInfo (ConvertFrom-RIIndex $installed).Text).Count -eq 1) 'Exactly one hook'
    Assert-Check ((Get-RIHash (ConvertTo-RIHook $installed -CssHash $hash)) -eq (Get-RIHash $installed)) 'Repeated hook install is byte-idempotent'
    Assert-Check ((Get-RIHash (ConvertTo-RIHook $installed -Remove)) -eq (Get-RIHash $original)) 'Restore preserves original bytes and newlines'
    $upgraded = [Text.Encoding]::UTF8.GetBytes((ConvertFrom-RIIndex $installed).Text.Replace('/assets/vendor.css','/assets/new-product.css'))
    $restored = (ConvertFrom-RIIndex (ConvertTo-RIHook $upgraded -Remove)).Text
    Assert-Check ($restored.Contains('new-product.css') -and -not $restored.Contains('rasinsider.css')) 'Restore preserves current upgraded product index'
    $utf16 = (New-Object Text.UnicodeEncoding($false,$true,$true))
    [byte[]]$wide = $utf16.GetPreamble() + $utf16.GetBytes('<html><head></head><body>Theme</body></html>')
    Assert-Check ((Get-RIHash (ConvertTo-RIHook (ConvertTo-RIHook $wide -CssHash $hash) -Remove)) -eq (Get-RIHash $wide)) 'UTF-16 BOM round trip'
    Assert-Throws { ConvertTo-RIHook ([Text.Encoding]::UTF8.GetBytes('<head></head>'+ $script:RIBegin)) -CssHash $hash } 'Reject malformed marker'
    Assert-Throws { ConvertTo-RIHook ([Text.Encoding]::UTF8.GetBytes((ConvertFrom-RIIndex $installed).Text + (ConvertFrom-RIIndex $installed).Text)) -CssHash $hash } 'Reject duplicate hook'
    Assert-Throws { ConvertTo-RIHook ([Text.Encoding]::UTF8.GetBytes('<head><link href="/userportal/rasinsider.css"></head>')) -CssHash $hash } 'Preserve unmarked existing prototype'
    $altered = [Text.Encoding]::UTF8.GetBytes((ConvertFrom-RIIndex $installed).Text.Replace($script:RIEnd,'<script>keep()</script>'+$script:RIEnd))
    Assert-Throws { ConvertTo-RIHook $altered -Remove } 'Do not delete unexpected content inside markers'
    Assert-Throws { ConvertFrom-RIIndex ([byte[]]@(255,255,255)) } 'Reject unsupported encoding'

    $portal = Join-Path $fixture 'www'; $null = [IO.Directory]::CreateDirectory($portal)
    $env:ProgramData = Join-Path $fixture 'programdata'
    [IO.File]::WriteAllBytes((Join-Path $portal 'index.html'),$original)
    $node = [PSCustomObject]@{ Farm = 'fixture'; SiteId = 1; Id = 10; Server = 'fixture.local'; AgentVersion = '22.0.0.28102' }
    $request = Get-RIRequest $node $portal 'index.html'
    $snapshot = Invoke-RIWorker Inspect $request
    Assert-Check ($snapshot.Health -eq 'Original' -and -not (Test-Path -LiteralPath $env:ProgramData)) 'Status is read-only'
    Assert-Throws { $r = Get-RIRequest $node $portal '../outside.html'; Invoke-RIWorker Inspect $r } 'Reject path traversal'
    $snapshot = Invoke-RIWorker Preflight $request
    $plan = Get-RIPlan $snapshot $request Install (Get-RIPreset)
    $request = $plan.Request; $request.TransactionId = [guid]::NewGuid().ToString('N')
    $null = Invoke-RIWorker Prepare $request
    Assert-Check ((Get-RIHash ([IO.File]::ReadAllBytes((Join-Path $portal 'index.html')))) -eq (Get-RIHash $original)) 'Prepare stages without changing portal index'
    Assert-Throws { Invoke-RIWorker Preflight $request } 'Active transaction blocks another deployment'
    $null = Invoke-RIWorker Commit $request
    $verified = Invoke-RIWorker Verify $request
    Assert-Check ($verified.Health -eq 'Healthy') 'Worker install commit and hash verification'
    $null = Invoke-RIWorker Finalize $request
    $snapshot = Invoke-RIWorker Inspect $request
    $same = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Install (Get-RIPreset)
    Assert-Check $same.NoChange 'Repeated install does not rewrite state'
    $same = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Reapply $null
    Assert-Check $same.NoChange 'Re-apply preserves saved configuration'
    # Simulated product upgrade removes hook; re-apply uses current product index.
    [IO.File]::WriteAllBytes((Join-Path $portal 'index.html'),[Text.Encoding]::UTF8.GetBytes('<html><head><meta name="upgraded" content="yes"></head><body>New Theme</body></html>'))
    $snapshot = Invoke-RIWorker Preflight $request
    $plan = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Reapply $null
    $request = $plan.Request; $request.TransactionId = [guid]::NewGuid().ToString('N')
    $null = Invoke-RIWorker Prepare $request; $null = Invoke-RIWorker Commit $request
    $null = Invoke-RIWorker Verify $request; $null = Invoke-RIWorker Finalize $request
    Assert-Check (([IO.File]::ReadAllText((Join-Path $portal 'index.html'))).Contains('upgraded')) 'Upgrade re-apply preserves new product index'
    $snapshot = Invoke-RIWorker Preflight $request
    $plan = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Restore $null
    $request = $plan.Request; $request.TransactionId = [guid]::NewGuid().ToString('N')
    $null = Invoke-RIWorker Prepare $request; $null = Invoke-RIWorker Commit $request
    $v = Invoke-RIWorker Verify $request; $null = Invoke-RIWorker Finalize $request
    Assert-Check ($v.Health -eq 'Original' -and ([IO.File]::ReadAllText((Join-Path $portal 'index.html'))).Contains('upgraded')) 'Surgical worker restore after upgrade'
    $snapshot = Invoke-RIWorker Inspect $request
    Assert-Check (Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Restore $null).NoChange 'Repeated restore is a no-op'
    # Crash recovery from a committed but unfinalized transaction.
    $snapshot = Invoke-RIWorker Preflight $request
    $plan = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Install (Get-RIPreset 'Midnight Blue')
    $request = $plan.Request; $request.TransactionId = [guid]::NewGuid().ToString('N')
    $baseline = $snapshot.IndexHash
    $null = Invoke-RIWorker Prepare $request; $null = Invoke-RIWorker Commit $request
    $null = Invoke-RIWorker Rollback $request; $null = Invoke-RIWorker Finalize $request
    Assert-Check ((Invoke-RIWorker Inspect $request).IndexHash -eq $baseline) 'Interrupted commit rolls back immediate snapshot'
    $snapshot = Invoke-RIWorker Preflight $request
    $plan = Get-RIPlan $snapshot (Get-RIRequest $node $portal 'index.html') Install (Get-RIPreset)
    $request = $plan.Request; $request.TransactionId = [guid]::NewGuid().ToString('N')
    $null = Invoke-RIWorker Prepare $request; $null = Invoke-RIWorker Commit $request
    [IO.File]::AppendAllText((Join-Path $portal 'index.html'),'<!-- Concurrent upgrade -->')
    Assert-Throws { Invoke-RIWorker Rollback $request } 'Rollback refuses unrelated concurrent upgrade'
    Assert-Check (([IO.File]::ReadAllText((Join-Path $portal 'index.html'))).Contains('Concurrent upgrade')) 'Concurrent edit remains intact'
    Write-Host "All $script:passed checks passed. No live RAS or Windows targets were contacted."
} finally {
    $env:ProgramData = $previousProgramData
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
