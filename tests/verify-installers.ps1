$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$required = @('install.ps1', 'install.sh', 'rime-ice.version', 'common/default.custom.yaml', 'common/double_pinyin_flypy.custom.yaml', 'weasel/weasel.custom.yaml')
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo $path))) { throw "Missing $path" }
}
if ((Get-Content -Raw -LiteralPath (Join-Path $repo 'install.ps1')) -notmatch 'git --exec-path') {
    throw 'Windows installer does not discover Git Bash from the active Git installation'
}
if ((Get-Content -Raw -LiteralPath (Join-Path $repo 'install.ps1')) -notmatch 'cygpath') {
    throw 'Windows installer does not convert custom drive paths for Git Bash'
}
foreach ($installer in @('install.ps1', 'install.sh')) {
    if ((Get-Content -Raw -LiteralPath (Join-Path $repo $installer)) -notmatch 'custom_phrase\.txt') {
        throw "$installer does not preserve an existing custom_phrase.txt"
    }
}

$target = Join-Path $env:TEMP 'rime-configs-installer-test'
if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
& (Join-Path $repo 'install.ps1') -Target $target -SkipUpstream -SkipDeploy
foreach ($file in @('default.custom.yaml', 'double_pinyin_flypy.custom.yaml', 'weasel.custom.yaml', 'emoji.schema.yaml', 'jyutping.schema.yaml')) {
    if (-not (Test-Path -LiteralPath (Join-Path $target $file))) { throw "Installer did not deploy $file" }
}
if (Get-ChildItem -LiteralPath $target -Recurse -Force | Where-Object Name -Match 'userdb|installation.yaml|user.yaml|custom_phrase') {
    throw 'Installer copied private runtime data'
}
Write-Output 'Installer self-check passed.'
