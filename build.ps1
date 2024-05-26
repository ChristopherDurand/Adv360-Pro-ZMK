# Main script logic
param (
    [string]$Target = "Left"
)

# Get the Docker command (assuming Docker Desktop is installed)
$DOCKER = "docker"

# Get the timestamp and commit hash
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmm"
$COMMIT = (git rev-parse --short HEAD) -replace "`n", ""

# Set SELinux options (not applicable on Windows, so they are empty)
$SELINUX1 = ""
$SELINUX2 = ""

# Function to get the current directory in Docker-compatible format
function Get-DockerPath {
    param (
        [string]$path
    )
    $path -replace "\\", "/"
}

# Function to execute the common build and run commands
function BuildAndRun {
    param (
        [bool]$buildRight
    )

    Write-Output "Running PowerShell script to generate version info"
    powershell -ExecutionPolicy Bypass -File bin/get_version.ps1 > $null

    Write-Output "Building Docker image..."
    & $DOCKER build --tag zmk --file Dockerfile .

    $currentDir = Get-Location
    $firmwarePath = Get-DockerPath "$currentDir/firmware"
    $configPath = Get-DockerPath "$currentDir/config"

    Write-Output "Running Docker container..."
    & $DOCKER run --rm -it --name zmk `
        -v "${firmwarePath}:/app/firmware$SELINUX1" `
        -v "${configPath}:/app/config:ro$SELINUX2" `
        -e "TIMESTAMP=$TIMESTAMP" `
        -e "COMMIT=$COMMIT" `
        -e "BUILD_RIGHT=$buildRight" `
        zmk

    Write-Output "Checking out config/version.dtsi"
    git checkout config/version.dtsi
}

# Target: all
function All {
    BuildAndRun -buildRight $true
}

# Target: left
function Left {
    BuildAndRun -buildRight $false
}

# Target: clean_firmware
function CleanFirmware {
    Write-Output "Cleaning firmware..."
    Remove-Item -Force -ErrorAction SilentlyContinue "firmware/*.uf2"
}

# Target: clean_image
function CleanImage {
    Write-Output "Cleaning Docker image..."
    & $DOCKER image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable
}

# Target: clean
function Clean {
    CleanFirmware
    CleanImage
}

# Execute the target
switch ($Target) {
    "All" { All }
    "Left" { Left }
    "CleanFirmware" { CleanFirmware }
    "CleanImage" { CleanImage }
    "Clean" { Clean }
    default { Write-Output "Unknown target: $Target" }
}
