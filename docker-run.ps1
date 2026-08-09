<#
.SYNOPSIS
    Builds and runs the agent-aegis security agent in Docker with Ollama support.

.DESCRIPTION
    This script builds a Docker image for agent-aegis and runs it with:
    - A mounted workspace directory
    - Connection to your local Ollama instance
    - Configurable model (defaults to qwen3.6:27b)
    - Choice of Ubuntu (default), Kali Linux, or Debian container
    - Optional vulnerable target containers for security testing

.PARAMETER WorkspaceDir
    The directory to mount into the container at /workspace.
    Defaults to the current directory.

.PARAMETER Model
    The Ollama model to use.
    Defaults to "qwen3.6:27b".

.PARAMETER ImageName
    Docker image name.
    Defaults to "agent-aegis".

.PARAMETER ContainerType
    Container type: "ubuntu" (default), "kali", or "debian".
    Kali includes full pentest toolkit (nmap, sqlmap, nikto, metasploit, etc.).
    Debian is a minimal base with common utilities.

.PARAMETER VulnContainer
    Vulnerable container to start alongside the agent.
    "none" (default), "web" (Flask app on port 5000), or "redis" (Redis 5.0.7 with CVE-2022-0543 on port 6379).

.PARAMETER AdditionalArgs
    Additional arguments to pass to the aegis command inside the container.

.PARAMETER ListModels
    If set, lists available models and exits.

.EXAMPLE
    .\docker-run.ps1
    Runs with Ubuntu container and default model.

.EXAMPLE
    .\docker-run.ps1 -ContainerType kali
    Runs with Kali container and full pentest toolkit.

.EXAMPLE
    .\docker-run.ps1 -VulnContainer web
    Runs with Ubuntu container and starts a vulnerable Flask web app on port 5000.

.EXAMPLE
    .\docker-run.ps1 -ContainerType kali -VulnContainer redis
    Runs Kali container with vulnerable Redis instance for exploitation practice.

.EXAMPLE
    .\docker-run.ps1 -WorkspaceDir "C:\my-project" -Model "llama3.1:8b" -ContainerType kali
    Runs Kali container with specific directory and model.

.EXAMPLE
    .\docker-run.ps1 -ListModels
    Lists available models.
#>

param(
    [string]$WorkspaceDir = ".",
    [string]$Model = "qwen3.6:27b",
    [string]$ImageName = "agent-aegis",
    [ValidateSet("ubuntu", "kali", "debian")]
    [string]$ContainerType = "ubuntu",
    [ValidateSet("none", "web", "redis")]
    [string]$VulnContainer = "none",
    [string]$AdditionalArgs = "",
    [switch]$ListModels
)

$ErrorActionPreference = "Stop"

# Resolve the workspace directory to an absolute path
$WorkspaceDir = (Resolve-Path -Path $WorkspaceDir).Path

$DockerDir = "$PSScriptRoot\packages\docker"
$Dockerfile = "$DockerDir\Dockerfile.$ContainerType"
if ($ContainerType -eq "ubuntu") {
    $Dockerfile = "$DockerDir\Dockerfile.ubuntu"
}
$ImageTag = "$ImageName-$ContainerType"

Write-Host "Building Docker image: $ImageTag (from $ContainerType)" -ForegroundColor Cyan
docker build -t $ImageTag -f $Dockerfile "$DockerDir"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit 1
}

# Create vuln-net if it doesn't exist
$networkExists = docker network ls --filter "name=vuln-net" --format "{{.Name}}" 2>$null
if ($networkExists -ne "vuln-net") {
    Write-Host "Creating vuln-net network..." -ForegroundColor Yellow
    docker network create vuln-net
}

# Start vulnerable container if requested
if ($VulnContainer -ne "none") {
    $VulnDir = "$DockerDir\vuln\vuln-$VulnContainer"

    Write-Host "Building vulnerable container: vuln-$VulnContainer..." -ForegroundColor Yellow
    docker build -t "vuln-$VulnContainer" -f "$VulnDir\Dockerfile" "$VulnDir"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build vulnerable container."
        exit 1
    }

    # Stop and remove existing container if running
    docker rm -f "vuln-$VulnContainer" -ErrorAction SilentlyContinue

    Write-Host "Starting vulnerable container: vuln-$VulnContainer..." -ForegroundColor Yellow
    docker run -d --rm --name "vuln-$VulnContainer" --network vuln-net "vuln-$VulnContainer"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start vulnerable container."
        exit 1
    }
    Write-Host "Vulnerable container vuln-$VulnContainer is running." -ForegroundColor Green
    Write-Host ""
}

Write-Host "Using Ollama model: $Model" -ForegroundColor Green
Write-Host "Workspace directory: $WorkspaceDir" -ForegroundColor Green
Write-Host "Container type: $ContainerType" -ForegroundColor Green
if ($VulnContainer -ne "none") {
    Write-Host "Vulnerable target: vuln-$VulnContainer" -ForegroundColor Green
}
Write-Host ""
Write-Host "Starting agent-aegis in Docker..." -ForegroundColor Cyan
Write-Host ""

# Run the container
$DockerArgs = @(
    "run", "--rm", "-it"
    "-e", "HOME=/root"
    "-e", "PI_MODEL=$Model"
    "-v", "${WorkspaceDir}:/workspace"
    "--add-host", "host.docker.internal:host-gateway"
    "--network", "vuln-net"
    $ImageTag
)

if ($ListModels) {
    $DockerArgs += @("--list-models")
} elseif ($AdditionalArgs) {
    $DockerArgs += $AdditionalArgs.Split(" ")
}

& docker @DockerArgs
