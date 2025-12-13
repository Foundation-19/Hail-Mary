$BYOND_ROOT = "C:\byond"
$BYOND_VERSION = "515.1633"
$BYOND_URL = "https://github.com/YOURORG/YOURREPO/releases/download/byond/${BYOND_VERSION}_byond_windows.zip"

# Use cached version if available
if (!(Test-Path "$BYOND_ROOT\bin\dm.exe")) {
    Write-Host "Installing BYOND $BYOND_VERSION..."

    Remove-Item -Recurse -Force $BYOND_ROOT -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $BYOND_ROOT | Out-Null

    Invoke-WebRequest -Uri $BYOND_URL -OutFile "$BYOND_ROOT\byond.zip"
    if (!(Test-Path "$BYOND_ROOT\byond.zip")) {
        Write-Error "BYOND download failed!"
        exit 1
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory("$BYOND_ROOT\byond.zip", $BYOND_ROOT)
    Remove-Item "$BYOND_ROOT\byond.zip"
} else {
    Write-Host "Using cached BYOND $BYOND_VERSION."
}

# Ensure dm.exe is in PATH
$env:PATH = "$BYOND_ROOT\bin;$env:PATH"

# Continue with Node install and build
bash tools/ci/install_node.sh
bash tools/build/build

exit $LASTEXITCODE
