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

try {
    $foldersToBackup = @(
        @{
            Path = "/opt/homeassistant/"
            ExcludePatterns = @(
                "config/home-assistant.log*"
            )
        }
        @{
            Path = "/opt/mosquitto/"
            ExcludePatterns = @(
                "log"
                "log/*"
            )
        }
        @{
            Path = "/opt/zigbee2mqtt/"
            ExcludePatterns = @(
                "data/log"
                "data/log/*"
                "data/log/*/*"
            )
        }
        @{
            Path = "/opt/esphome/"
            ExcludePatterns = @()
        }
        @{
            Path = "/opt/ewelink/"
            ExcludePatterns = @()
        }
    )

    $backupFilenamePrefix = "home-automation-backup-"
    $backupTime = [DateTime]::UtcNow
    $dailyBackupDateFormat = "yyyy-MM-dd"
    $monthlyBackupDateFormat = "yyyy-MMM"
    $dailyBackupFileName = "$($backupFilenamePrefix)$($backupTime.ToString($dailyBackupDateFormat)).tgz"
    $previousMonthBackupFileName = "$($backupFilenamePrefix)$($backupTime.AddMonths(-1).ToString($monthlyBackupDateFormat)).tgz"
    $dailyBackupPath = Join-Path $Target $dailyBackupFileName
    $previousMonthBackupPath = Join-Path $Target $previousMonthBackupFileName

    $tarArguments = @(
        "tar"
        "--create"
        "--gzip"
        "--file=$($dailyBackupPath)"
        "--recursion"
        "--verbose"
    )
    foreach ($folderToBackup in $foldersToBackup) {
        $folder = $folderToBackup.Path
        $folderParent = Split-Path -Path $folder -Parent
        $folderName = Split-Path -Path $folder -Leaf

        foreach ($excludePattern in $folderToBackup.ExcludePatterns) {
            $tarArguments += "--exclude=$($folderName)/$excludePattern"
        }

        $tarArguments += "--directory=$folderParent"
        $tarArguments += "$folderName"
    }
    $tarCommand = $tarArguments -join " "

    Write-Host "Creating new backup $($dailyBackupPath)" -ForegroundColor Blue
    Write-Host "Executing: $tarCommand" -ForegroundColor Gray
    Invoke-Expression $tarCommand
    chown $User $dailyBackupPath
    chgrp root $dailyBackupPath
    chmod g+w $dailyBackupPath

    if (-not (Test-Path $previousMonthBackupPath)) {
        Write-Host "Storing monthly backup $($previousMonthBackupPath)"
        Copy-Item -Path $dailyBackupPath -Destination $previousMonthBackupPath
        chown $User $previousMonthBackupPath
        chgrp root $previousMonthBackupPath
    }

    $earliestBackupToKeep = [datetime]::Today.AddDays(-1 * $DaysToKeep)
    Write-Host "Processing existing backups, keeping up until $($earliestBackupToKeep.ToString($dailyBackupDateFormat))" -ForegroundColor Blue
    $backupFiles = Get-ChildItem -Path $Target -File -Recurse:$false | Where-Object { $_.Extension -in @(".zip", ".tgz") }
    foreach ($backupFile in $backupFiles) {
        Write-Host $backupFile.FullName -ForegroundColor Gray

        # Daily backup?
        if ($backupFile.Name -match "$([System.Text.RegularExpressions.Regex]::Escape($backupFilenamePrefix))(?<date>\d{4}-\d{2}-\d{2})\.(zip|tgz)$") {
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

        if ($backupFile.Name -match "$([System.Text.RegularExpressions.Regex]::Escape($backupFilenamePrefix))(?<date>\d{4}-\w{3})\.(zip|tgz)$") {
            Write-Verbose "Ignoring monthly backup"
            continue
        }

        Write-Warning "Unable to parse date from backup file $($backupFile.Name)"
    }
}
catch {
    Get-Error
    throw
}
