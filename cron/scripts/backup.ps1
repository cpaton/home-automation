#! /usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$dockerCommand = @"
docker container run --rm ``
--mount type=bind,source=/opt,target=/opt ``
--mount type=bind,source=/home/craig/OneDrive,target=/home/craig/OneDrive ``
--entrypoint pwsh ``
mcr.microsoft.com/dotnet/sdk:9.0-noble ``
/opt/home-automation/scripts/backup.ps1
"@
Write-Host $dockerCommand
Invoke-Expression $dockerCommand