# Pester 5 regression tests. Only local fixtures and mocked transport are used.
BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $root 'RAS-UserPortal-SkinManager.ps1')
    function Test-RIAdministrator { }
    $script:previousProgramData = $env:ProgramData
}
AfterAll { $env:ProgramData = $script:previousProgramData }
Describe 'Custom skins and surgical hook' {
    It 'rejects injected CSS values' {
        $skin = Get-RIPreset; $skin.Accent = '#FFFFFF; color:red'
        { Test-RISkin $skin } | Should -Throw
    }
    It 'rejects infinity and out-of-range numbers' {
        $skin = Get-RIPreset; $skin.Blur = [double]::PositiveInfinity
        { Test-RISkin $skin } | Should -Throw
        $skin.Blur = 0; $skin.Radius = 49
        { Test-RISkin $skin } | Should -Throw
    }
    It 'renders all presets standalone' {
        foreach ($name in 'Dark Glass','Midnight Blue','Light Glass','RASInsider','Graphite','Forest','Warm Ivory','Bordeaux','Aubergine','Liquid Glass','Ruby','Custom') {
            Get-RICss (Get-RIPreset $name) | Should -Match '--ri-'
        }
    }
    It 'keeps existing presets identical to their original JSON examples' {
        foreach ($file in 'dark-glass.json','midnight-blue.json','light-glass.json','rasinsider.json') {
            $original = Get-Content (Join-Path $root "skins/$file") -Raw | ConvertFrom-Json
            $current = Get-RIPreset $original.Name
            foreach ($property in $original.PSObject.Properties) {
                $current.($property.Name) | Should -Be $property.Value
            }
        }
    }
    It 'round-trips new JSON examples to the same CSS as embedded presets' {
        foreach ($file in 'graphite.json','forest.json','warm-ivory.json','bordeaux.json','aubergine.json','liquid-glass.json','ruby.json') {
            $skin = Get-Content (Join-Path $root "skins/$file") -Raw | ConvertFrom-Json
            Get-RICss $skin | Should -Be (Get-RICss (Get-RIPreset $skin.Name))
        }
    }
    It 'limits Liquid Glass highlights to the named preset' {
        Get-RICss (Get-RIPreset 'Liquid Glass') | Should -Match 'box-shadow: inset'
        foreach ($name in 'Dark Glass','Ruby','Warm Ivory') {
            Get-RICss (Get-RIPreset $name) | Should -Not -Match 'box-shadow: inset'
        }
    }
    It 'preserves an upgraded current index during restore' {
        $hash = 'a' * 64
        $bytes = [Text.Encoding]::UTF8.GetBytes('<html><head><script src="new-product.js"></script></head></html>')
        $hooked = ConvertTo-RIHook $bytes -CssHash $hash
        (Get-RIHash (ConvertTo-RIHook $hooked -Remove)) | Should -Be (Get-RIHash $bytes)
    }
    It 'does not delete unexpected code between markers' {
        $bytes = [Text.Encoding]::UTF8.GetBytes('<head>'+ $script:RIBegin + '<script>keep()</script>' + $script:RIEnd + '</head>')
        { ConvertTo-RIHook $bytes -Remove } | Should -Throw
    }
    It 'round-trips the serialized remote worker without parser errors' {
        $errors = $null; $tokens = $null
        $null = [Management.Automation.Language.Parser]::ParseInput($script:RIRemoteWorker.ToString(),[ref]$tokens,[ref]$errors)
        $errors.Count | Should -Be 0
        $script:RIRemoteWorker.ToString() | Should -Match 'Invoke-RIWorker -Operation \$Operation -Request \$Request'
    }
}
Describe 'Multiple Gateways and recovery' {
    BeforeEach {
        $script:fixture = Join-Path $root ('ri-tests-' + [guid]::NewGuid().ToString('N'))
        $null = [IO.Directory]::CreateDirectory($script:fixture)
        $script:targets = @()
        $script:trace = New-Object 'Collections.Generic.List[string]'
        $script:failPreflight = $false; $script:failCommit = $false; $script:concurrentEdit = $false
        foreach ($id in 1,2) {
            $dir = Join-Path $script:fixture ("gateway$id")
            $portal = Join-Path $dir 'www'; $null = [IO.Directory]::CreateDirectory($portal)
            [IO.File]::WriteAllText((Join-Path $portal 'index.html'),'<html><head><meta name="vendor" content="unchanged"></head><body>Theme</body></html>')
            $node = [PSCustomObject]@{ Farm = 'fixture'; SiteId = $id; Id = $id; Server = "gw$id.local"; AgentVersion = '22.0.0.28102' }
            $request = Get-RIRequest $node $portal 'index.html'
            $script:targets += [PSCustomObject]@{ Node = $node; Session = $null; Request = $request; FixtureProgramData = Join-Path $dir 'programdata' }
        }
        $script:coordinator = Join-Path $script:fixture 'coordinator'
        Mock Invoke-RITarget {
            param($Target,$Operation,$Request)
            $script:trace.Add("$Operation-$($Target.Node.Id)")
            $env:ProgramData = $Target.FixtureProgramData
            if ($Operation -eq 'Preflight' -and $Target.Node.Id -eq 2 -and $script:failPreflight) { throw 'Injected pre-flight failure' }
            if ($Operation -eq 'Commit' -and $Target.Node.Id -eq 2 -and $script:failCommit) {
                if ($script:concurrentEdit) { [IO.File]::AppendAllText((Join-Path $script:targets[0].Request.PortalRoot 'index.html'),'<!-- concurrent upgrade -->') }
                throw 'Injected second Gateway commit failure'
            }
            Invoke-RIWorker $Operation $Request
        }
    }
    AfterEach {
        if (Test-Path -LiteralPath $script:fixture) { Remove-Item -LiteralPath $script:fixture -Recurse -Force }
    }
    It 'pre-flights every target and performs zero commits when one fails' {
        $script:failPreflight = $true
        { Invoke-RIDeployment $script:targets Install (Get-RIPreset) $script:coordinator } | Should -Throw '*No live portal*'
        @($script:trace | Where-Object { $_ -like 'Preflight-*' }).Count | Should -Be 2
        @($script:trace | Where-Object { $_ -like 'Prepare-*' -or $_ -like 'Commit-*' }).Count | Should -Be 0
        foreach ($target in $script:targets) { (Join-Path $target.Request.PortalRoot 'rasinsider.css') | Should -Not -Exist }
    }
    It 'stages every selected Gateway before the first live commit and verifies all' {
        Invoke-RIDeployment $script:targets Install (Get-RIPreset) $script:coordinator
        $script:trace.IndexOf('Prepare-2') | Should -BeLessThan $script:trace.IndexOf('Commit-1')
        @($script:trace | Where-Object { $_ -like 'Verify-*' }).Count | Should -Be 2
        foreach ($target in $script:targets) {
            $snapshot = Invoke-RITarget $target Inspect $target.Request
            $snapshot.Health | Should -Be 'Healthy'
            $snapshot.ActiveTransaction | Should -BeNullOrEmpty
        }
        (Get-ChildItem $script:coordinator -Filter '*.json' | Get-Content -Raw | ConvertFrom-Json).Phase | Should -Be 'Completed'
    }
    It 'rolls back both prepared targets after a second Gateway commit failure' {
        $script:failCommit = $true
        { Invoke-RIDeployment $script:targets Install (Get-RIPreset) $script:coordinator } | Should -Throw '*rollback verified*'
        foreach ($target in $script:targets) {
            $snapshot = Invoke-RITarget $target Inspect $target.Request
            $snapshot.Health | Should -Be 'Original'
            $snapshot.ActiveTransaction | Should -BeNullOrEmpty
        }
        (Get-ChildItem $script:coordinator -Filter '*.json' | Get-Content -Raw | ConvertFrom-Json).Phase | Should -Be 'RolledBack'
    }
    It 'reports partial rollback and retains recovery journal instead of overwriting concurrent upgrade' {
        $script:failCommit = $true; $script:concurrentEdit = $true
        { Invoke-RIDeployment $script:targets Install (Get-RIPreset) $script:coordinator } | Should -Throw '*Recovery required*'
        $journal = Get-ChildItem $script:coordinator -Filter '*.json' | Get-Content -Raw | ConvertFrom-Json
        $journal.Phase | Should -Be 'RecoveryRequired'
        $journal.FailedTargets | Should -Contain 'gw1.local'
        [IO.File]::ReadAllText((Join-Path $script:targets[0].Request.PortalRoot 'index.html')) | Should -Match 'concurrent upgrade'
        (Invoke-RITarget $script:targets[1] Inspect $script:targets[1].Request).Health | Should -Be 'Original'
    }
    It 'detects drift between pre-flight and preparation without overwriting it' {
        $target = $script:targets[0]
        $snapshot = Invoke-RITarget $target Preflight $target.Request
        $plan = Get-RIPlan $snapshot $target.Request Install (Get-RIPreset)
        $target.Request = $plan.Request; $target.Request.TransactionId = [guid]::NewGuid().ToString('N')
        [IO.File]::AppendAllText((Join-Path $target.Request.PortalRoot 'index.html'),'<!-- manual change -->')
        { Invoke-RITarget $target Prepare $target.Request } | Should -Throw '*Concurrent drift*'
        [IO.File]::ReadAllText((Join-Path $target.Request.PortalRoot 'index.html')) | Should -Match 'manual change'
    }
    It 'refuses a prototype collision unless explicitly adopted' {
        $target = $script:targets[0]
        [IO.File]::WriteAllText((Join-Path $target.Request.PortalRoot 'rasinsider.css'),'/* existing prototype */')
        $snapshot = Invoke-RITarget $target Preflight $target.Request
        { Get-RIPlan $snapshot $target.Request Install (Get-RIPreset) } | Should -Throw '*unmanaged*'
        (Get-RIPlan $snapshot $target.Request Install (Get-RIPreset) -PrototypeAdopted).NoChange | Should -BeFalse
    }
}
Describe 'RAS API property contracts and scope' {
    It 'rejects missing discovery properties instead of guessing' {
        { Get-RIRequiredProperty ([PSCustomObject]@{Hostname='gw.local'}) 'Server' } | Should -Throw '*contract mismatch*'
    }
    It 'selects multiple Sites from API inventory' {
        $inventory = [PSCustomObject]@{ Sites = @([PSCustomObject]@{Id=1},[PSCustomObject]@{Id=2}); Gateways = @([PSCustomObject]@{SiteId=1;Id=11},[PSCustomObject]@{SiteId=2;Id=21}) }
        $scope = Select-RIScope $inventory ([uint32[]]@(1,2)) @()
        $scope.Count | Should -Be 2
        { Select-RIScope $inventory @() ([uint32[]]@(99)) } | Should -Throw '*Unknown Gateway*'
    }
}
