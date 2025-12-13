# tools/ci/build.ps1
param()

$BYOND_ROOT = "C:\byond"
$BYOND_VERSION = "515.1633"
$BYOND_URL = "https://github.com/YOURORG/YOURREPO/releases/download/byond/515.1633_byond_windows.zip"

# Ensure BYOND folder exists
if (!(Test-Path "$BYOND_ROOT\bin\dm.exe")) {
    Write-Host "Installing BYOND $BYOND_VERSION..."

    # Clean old folder
    Remove-Item -Recurse -Force $BYOND_ROOT -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $BYOND_ROOT | Out-Null

    # Download zip
    try {
        Invoke-WebRequest -Uri $BYOND_URL -OutFile "$BYOND_ROOT\byond.zip" -UseBasicParsing
    } catch {
        Write-Error "BYOND download failed! Check that the URL exists and is accessible."
        exit 1
    }

    if (!(Test-Path "$BYOND_ROOT\byond.zip")) {
        Write-Error "BYOND zip does not exist after download."
        exit 1
    }

    # Extract zip
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$BYOND_ROOT\byond.zip", $BYOND_ROOT)
    } catch {
        Write-Error "Failed to extract BYOND zip. File may be corrupt."
        exit 1
    }

    # Remove zip
    Remove-Item "$BYOND_ROOT\byond.zip"
} else {
    Write-Host "Using cached BYOND $BYOND_VERSION."
}

# Add BYOND to PATH so dm.exe can be called
$env:PATH = "$BYOND_ROOT\bin;$env:PATH"

# Install Node if needed
bash tools/ci/install_node.sh

# Run build
bash tools/build/build

exit $LASTEXITCODE
