$BYOND_ROOT = "C:\byond"
$BYOND_VERSION = "$env:BYOND_MAJOR.$env:BYOND_MINOR"
$BYOND_URL = "https://github.com/YOURORG/YOURREPO/releases/download/byond/${BYOND_VERSION}_byond_windows.zip"

if (!(Test-Path "$BYOND_ROOT\bin\dm.exe")) {
    Write-Host "Installing BYOND $BYOND_VERSION"

    Remove-Item -Recurse -Force $BYOND_ROOT -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $BYOND_ROOT | Out-Null

    Invoke-WebRequest -Uri $BYOND_URL -OutFile "$BYOND_ROOT\byond.zip"
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$BYOND_ROOT\byond.zip", $BYOND_ROOT)
    Remove-Item "$BYOND_ROOT\byond.zip"
} else {
    Write-Host "Using cached BYOND"
}

$env:PATH = "$BYOND_ROOT\bin;$env:PATH"

bash tools/ci/install_node.sh
bash tools/build/build

exit $LASTEXITCODE
