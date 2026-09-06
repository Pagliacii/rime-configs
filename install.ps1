param(
    [string]$Target,
    [switch]$SkipUpstream,
    [switch]$SkipDeploy
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
if (-not $Target) {
    if (-not $env:APPDATA) { throw 'Cannot detect the Rime user directory; pass -Target.' }
    $Target = Join-Path $env:APPDATA 'Rime'
}
$Target = [IO.Path]::GetFullPath($Target)
New-Item -ItemType Directory -Path $Target -Force | Out-Null

if (-not $SkipUpstream) {
    $version = (Get-Content -Raw -LiteralPath (Join-Path $repo 'rime-ice.version')).Trim()
    $plum = Join-Path $repo '.cache\plum'
    if (Test-Path -LiteralPath (Join-Path $plum '.git')) {
        git -C $plum pull --ff-only
    } else {
        New-Item -ItemType Directory -Path (Split-Path -Parent $plum) -Force | Out-Null
        git clone --depth 1 https://github.com/rime/plum.git $plum
    }
    $gitExecPath = (& git --exec-path).Trim()
    $gitRoot = Split-Path (Split-Path (Split-Path $gitExecPath -Parent) -Parent) -Parent
    $bash = @(
        (Join-Path $gitRoot 'bin\bash.exe'),
        'C:\Program Files\Git\bin\bash.exe',
        (Get-Command bash.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if (-not $bash) { throw 'Git Bash is required to install rime-ice on Windows.' }
    $targetForBash = (& $bash -lc 'cygpath -u "$1"' _ $Target).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $targetForBash) { throw 'Could not convert the Rime directory for Git Bash.' }
    $phrase = Join-Path $Target 'custom_phrase.txt'
    $phraseBackup = if (Test-Path -LiteralPath $phrase) { New-TemporaryFile }
    if ($phraseBackup) { Copy-Item -LiteralPath $phrase -Destination $phraseBackup -Force }
    $oldRimeDir = $env:rime_dir
    try {
        $env:rime_dir = $targetForBash
        & $bash (Join-Path $plum 'rime-install') "iDvel/rime-ice@$version"
        if ($LASTEXITCODE -ne 0) { throw 'Plum failed to install rime-ice.' }
    } finally {
        $env:rime_dir = $oldRimeDir
        if ($phraseBackup) {
            Copy-Item -LiteralPath $phraseBackup -Destination $phrase -Force
            Remove-Item -LiteralPath $phraseBackup -Force
        }
    }
}

Copy-Item -Path (Join-Path $repo 'common\*.yaml') -Destination $Target -Force
Copy-Item -Path (Join-Path $repo 'legacy\*.yaml') -Destination $Target -Force
Copy-Item -Path (Join-Path $repo 'weasel\*.yaml') -Destination $Target -Force

if (-not $SkipDeploy) {
    $key = Get-ItemProperty 'HKLM:\Software\WOW6432Node\Rime\Weasel' -ErrorAction SilentlyContinue
    $deployer = if ($key.WeaselRoot) { Join-Path $key.WeaselRoot 'WeaselDeployer.exe' }
    if ($deployer -and (Test-Path -LiteralPath $deployer)) {
        & $deployer /deploy
    } else {
        Write-Warning 'Configuration installed; redeploy your Rime frontend manually.'
    }
}

Write-Output "Rime configuration installed in $Target"
