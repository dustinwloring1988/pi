<#
.SYNOPSIS
    Builds and runs the pi coding-agent in Docker with Ollama support.

.DESCRIPTION
    This script builds a Docker image for pi-coding-agent and runs it with:
    - A mounted workspace directory
    - Connection to your local Ollama instance
    - Configurable model (defaults to qwen3.6:27b)

.PARAMETER WorkspaceDir
    The directory to mount into the container at /workspace.
    Defaults to the current directory.

.PARAMETER Model
    The Ollama model to use.
    Defaults to "qwen3.6:27b".

.PARAMETER ImageName
    Docker image name.
    Defaults to "pi-coding-agent".

.PARAMETER AdditionalArgs
    Additional arguments to pass to the pi command inside the container.

.PARAMETER NoCache
    If set, builds Docker images with --no-cache to ensure latest packages are installed.

.EXAMPLE
    .\docker-coding-agent.ps1
    Runs with default model.

.EXAMPLE
    .\docker-coding-agent.ps1 -WorkspaceDir "C:\my-project" -Model "qwen3.6:35b"
    Runs with specific directory and model.
#>

param(
    [string]$WorkspaceDir = ".",
    [string]$Model = "qwen3.6:27b",
    [string]$ImageName = "pi-coding-agent",
    [string]$AdditionalArgs = "",
    [switch]$NoCache
)

$ErrorActionPreference = "Stop"

$WorkspaceDir = (Resolve-Path -Path $WorkspaceDir).Path

$DockerDir = "$PSScriptRoot\packages\docker"
$Dockerfile = "$DockerDir\Dockerfile.coding-agent"
$ImageTag = $ImageName

Write-Host "Building Docker image: $ImageTag" -ForegroundColor Cyan
$BuildArgs = @("build", "-t", $ImageTag, "-f", $Dockerfile, "$DockerDir")
if ($NoCache) { $BuildArgs = @("build", "--no-cache", "-t", $ImageTag, "-f", $Dockerfile, "$DockerDir") }
& docker @BuildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit 1
}

Write-Host "Using Ollama model: $Model" -ForegroundColor Green
Write-Host "Workspace directory: $WorkspaceDir" -ForegroundColor Green
Write-Host ""
Write-Host "Starting pi-coding-agent in Docker..." -ForegroundColor Cyan
Write-Host ""

$DockerArgs = @(
    "run", "--rm", "-it"
    "-e", "HOME=/root"
    "-e", "PI_MODEL=$Model"
    "-v", "${WorkspaceDir}:/workspace"
    "--add-host", "host.docker.internal:host-gateway"
    $ImageTag
)

if ($AdditionalArgs) {
    $DockerArgs += $AdditionalArgs.Split(" ")
}

& docker @DockerArgs
