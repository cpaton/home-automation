#! /usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$dockerCommand = @"
docker container run --rm --interactive --tty ``
--name cron ``
--mount type=bind,source=$(Join-Path $PSScriptRoot "scripts" -Resolve),target=/cron ``
--mount type=bind,source=$(Join-Path $PSScriptRoot "cron.d" -Resolve),target=/etc/cron.d ``
--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock ``
cpaton/cron:latest
"@
Invoke-Expression $dockerCommand