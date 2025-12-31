#! /usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Service
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$repositoryRoot = Join-Path $PSScriptRoot ".." -Resolve

docker compose `
    --project-name home-automation `
    --project-directory ( Join-Path $repositoryRoot "docker-compose" -Resolve ) `
    restart $Service