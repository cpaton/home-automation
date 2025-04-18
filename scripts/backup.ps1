#! /usr/bin/env pwsh

<#
.SYNOPSIS
Creates backups of home-automation container data keeping a rolling set of daily backups and 1 per month
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Location where backups are stored
    [Parameter()]
    [string]
    $Target = "/home/craig/OneDrive/home-automation-backup",
    # Number of daily backups to keep
    [Parameter()]
    [int]
    $DaysToKeep = 7,
    # User who should own the backups
    [Parameter()]
    [string]
    $User = "1000"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$foldersToBackup = @(
    "/opt/homeassistant/"
    "/opt/mosquitto/"
    # "/opt/portainer/"
    "/opt/zigbee2mqtt/"
)

$backupFilenamePrefix = "home-automation-backup-"
$backupTime = [DateTime]::UtcNow
$dailyBackupDateFormat = "yyyy-MM-dd"
$monthlyBackupDateFormat = "yyyy-MMM"
$dailyBackupFileName = "$($backupFilenamePrefix)$($backupTime.ToString($dailyBackupDateFormat)).zip"
$previousMonthBackupFileName = "$($backupFilenamePrefix)$($backupTime.AddMonths(-1).ToString($monthlyBackupDateFormat)).zip"
$dailyBackupPath = Join-Path $Target $dailyBackupFileName
$previousMonthBackupPath = Join-Path $Target $previousMonthBackupFileName

Write-Host "Creating new backup $($dailyBackupPath)" -ForegroundColor Blue
Compress-Archive `
    -Path $foldersToBackup `
    -DestinationPath $dailyBackupPath `
    -Force `
    -Verbose:$false
chown $User $dailyBackupPath
chgrp root $dailyBackupPath
chmod g+w $dailyBackupPath

if (-not (Test-Path $previousMonthBackupFileName)) {
    Write-Host "Storing monthly backup $($previousMonthBackupPath)"
    Copy-Item -Path $dailyBackupPath -Destination $previousMonthBackupPath
    chown $User $previousMonthBackupPath
    chgrp root $previousMonthBackupPath
}

$earliestBackupToKeep = [datetime]::Today.AddDays(-1 * $DaysToKeep)
Write-Host "Processing existing backups, keeping up until $($earliestBackupToKeep.ToString($dailyBackupDateFormat))" -ForegroundColor Blue
$backupFiles = Get-ChildItem -Path $Target -Filter "*.zip"
foreach ($backupFile in $backupFiles) {
    Write-Host $backupFile.FullName -ForegroundColor Gray

    # Daily backup?
    if ($backupFile.Name -match "$([System.Text.RegularExpressions.Regex]::Escape($backupFilenamePrefix))(?<date>\d{4}-\d{2}-\d{2})\.zip") {
        $backupDate = [DateTime]::ParseExact($Matches["date"], $dailyBackupDateFormat, [System.Globalization.CultureInfo]::InvariantCulture)
        if ($backupDate -ge $earliestBackupToKeep) {
            Write-Verbose "Keeping backup as within time window"
        }
        else {
            Write-Host "Removing old backup $($backupFile.Name)" -ForegroundColor Yellow
            Remove-Item -Path $backupFile.FullName
        }

        continue
    }

    if ($backupFile.Name -match "$([System.Text.RegularExpressions.Regex]::Escape($backupFilenamePrefix))(?<date>\d{4}-\w{3})\.zip") {
        Write-Verbose "Ignoring monthly backup"
        continue
    }

    Write-Warning "Unable to parse date from backup file $($backupFile.Name)"
}
