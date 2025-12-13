# tools/ci/build.ps1
$ErrorActionPreference = "Stop"

$BYOND_ROOT = "C:/byond"
$BYOND_VERSION = "515.1633"
$BYOND_ZIP = "$BYOND_ROOT.zip"

# Download BYOND if it doesn't exist or wrong version
if (!(Test-Path "$BYOND_ROOT\bin\dm.exe") -or !(Test-Path "$BYOND_ROOT\version.txt") -or (Get-Content "$BYOND_ROOT\version.txt") -ne $BYOND_VERSION) {
    Write-Host "Downloading BYOND $BYOND_VERSION..."

    # Ensure clean slate
    if (Test-Path $BYOND_ROOT) { Remove-Item -Recurse -Force $BYOND_ROOT }
    if (Test-Path $BYOND_ZIP) { Remove-Item -Force $BYOND_ZIP }

    # Download BYOND zip
    $url = "https://secure.byond.com/download/build/515/515.1633_byond_windows.zip"
    Invoke-WebRequest -Uri $url -OutFile $BYOND_ZIP -UseBasicParsing

    if (!(Test-Path $BYOND_ZIP) -or ((Get-Item $BYOND_ZIP).Length -lt 5000000)) {
        Write-Error "BYOND zip download failed or is too small!"
        exit 1
    }

    # Extract
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($BYOND_ZIP, "C:/")
    } catch {
        Write-Error "Failed to extract BYOND zip: $_"
        exit 1
    }

    Remove-Item $BYOND_ZIP

    # Save version
    $BYOND_VERSION | Out-File "$BYOND_ROOT/version.txt" -Encoding ASCII
}

# Add BYOND to PATH for this session
$env:PATH = "$BYOND_ROOT\bin;$env:PATH"

# Verify dm.exe exists
if (!(Test-Path "$BYOND_ROOT\bin\dm.exe")) {
    Write-Error "dm.exe not found! BYOND installation failed."
    exit 1
}

# Install Node and build project
bash tools/ci/install_node.sh
bash tools/build/build

exit $LASTEXITCODE
