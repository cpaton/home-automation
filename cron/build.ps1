#! /usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$dockerCommand = "docker buildx build --pull --tag cpaton/cron:latest $($PSScriptRoot)"
Invoke-Expression $dockerCommand