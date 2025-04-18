#! /usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$repositoryRoot = Join-Path $PSScriptRoot ".." -Resolve

docker compose `
    --project-name home-automation `
    --project-directory ( Join-Path $repositoryRoot "docker-compose" -Resolve ) `
    up `
    --detach `
    --remove-orphans