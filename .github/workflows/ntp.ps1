Import-Module -Name AWSPowerShell
Function Get-NtpSyncStatus {
    $ntpStatus = Get-Service w32time -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
    if ($ntpStatus -eq 'Running') {
        $statusOutput = w32tm /query /status
        $metrics = @{
            "LeapIndicator" = ($statusOutput | Select-String -Pattern '^Leap Indicator:\s+(\d)').Matches.Groups[1].Value
            "Stratum" = ($statusOutput | Select-String -Pattern '^Stratum:\s+(\d+)').Matches.Groups[1].Value
            "Precision" = ($statusOutput | Select-String -Pattern '^Precision:\s+(-?\d+)').Matches.Groups[1].Value
            "RootDelay" = ($statusOutput | Select-String -Pattern '^Root Delay:\s+(.*)').Matches.Groups[1].Value
            "RootDispersion" = ($statusOutput | Select-String -Pattern '^Root Dispersion:\s+(.*)').Matches.Groups[1].Value
            "LastSyncTime" = ($statusOutput | Select-String -Pattern '^Last Successful Sync Time:\s+(.+)').Matches.Groups[1].Value
            "PollInterval" = ($statusOutput | Select-String -Pattern '^Poll Interval:\s+(\d+)').Matches.Groups[1].Value
        }
        $dimensions = @{
            "Source" = ($statusOutput | Select-String -Pattern '^Source:\s+(.+)').Matches.Groups[1].Value
            "ReferenceId" = ($statusOutput | Select-String -Pattern '^ReferenceId:\s+(.+)').Matches.Groups[1].Value
        }
        $ntpStatus = @{
            "Status" = "Running"
            "Metrics" = $metrics
            "Dimensions" = $dimensions
        }
    }
    else {
        $ntpStatus = @{
            "Status" = "Not Running"
            "Metrics" = @{}
            "Dimensions" = @{}
        }
    }
    return $ntpStatus
}

$ntpSyncStatus = Get-NtpSyncStatus

$status = Get-Service w32time -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
$referenceId = [regex]::Match($ntpSyncStatus.Dimensions.ReferenceId, "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}").Value.Replace('.', '')
$source = $ntpSyncStatus.Dimensions.Source.Split(',')[0].Trim().Replace('.', '')
$leapIndicator = [int]$ntpSyncStatus.metrics.LeapIndicator
$rootDispersion = [double]::Parse($ntpSyncStatus.metrics.RootDispersion.Trim('s')).ToString("##.###############")
$rootDelay = [double]::Parse($ntpSyncStatus.metrics.RootDelay.Trim('s')).ToString("##.###############")
$precision = [int]$ntpSyncStatus.metrics.Precision
$pollInterval = ([int]$ntpSyncStatus.metrics.PollInterval).ToString("##.###############")
$stratum = [int]$ntpSyncStatus.metrics.Stratum
$lastSyncTime = ((New-TimeSpan -Start ($ntpSyncStatus.metrics.LastSyncTime) -End (Get-Date)).TotalSeconds).ToString("##.###############")
$upstreamTime = & w32tm /stripchart /computer:169.254.169.123 /samples:1 /dataonly
$match = [regex]::Match($upstreamTime, '(\d{2}:\d{2}:\d{2}),\s+([-+]?\d+\.\d+s)')
$timeDifference = ([double]$match.Groups[2].Value.Trim('s')).ToString("##.###############")
$clockErrorBound = [double]$timeDifference+(0.5 * $rootDelay + $rootDispersion).ToString("##.###############")
$numPeers = (w32tm /query /peers | Select-String -Pattern "Peers" | ForEach-Object {($_ -split ' ')[1]})
$instanceId = Invoke-WebRequest -Uri 169.254.169.254/latest/meta-data/instance-id/ -UseBasicParsing | Select-Object -Expand Content
$hostname = hostname


$customMetricData = @(
    @{
        MetricName = "SourceIP"
        Value = $source
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "SourceIP"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "ReferenceIP"
        Value = $referenceId
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "ReferenceIP"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "RootDispersion"
        Value = $rootDispersion
        Unit = "Seconds"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "RootDispersion"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "Precision"
        Value = $precision
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "Precision"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "PollInterval"
        Value = $pollInterval
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "PollInterval"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "Stratum"
        Value = $stratum
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "Stratum"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "RootDelay"
        Value = $rootDelay
        Unit = "Seconds"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "RootDelay"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "LeapIndicator"
        Value = $leapIndicator
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "LeapIndicator"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "LastSyncAgo"
        Value = $lastSyncTime
        Unit = "Seconds"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "LastSyncAgo"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "ClockErrorBound"
        Value = $clockErrorBound
        Unit = "Milliseconds"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "ClockErrorBound"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    },
    @{
        MetricName = "TimeDrift"
        Value = $timeDifference
        Unit = "Milliseconds"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "TimeDrift"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    }
    @{
        MetricName = "NumberOfPeers"
        Value = $numPeers
        Unit = "Count"
        Dimensions = @(
            @{
                Name = "InstanceID"
                Value = $instanceId
            }
            @{
                Name = "Hostname"
                Value = $hostname
            }
            @{
                Name = "Name"
                Value = "NumberOfPeers"
            }
            @{
                Name = "Status"
                Value = $status
            }
        )
    }


)
# Send the custom metric data to CloudWatch
Write-CWMetricData -Namespace "NTPTime" -MetricData $customMetricData

# Write-Host "ReferenceId: $referenceId"
# Write-Host "Source: $source"
# Write-Host "RootDispersion: $rootDispersion"
# Write-Host "Precision: $precision"
# Write-Host "PollInterval: $pollInterval"
# Write-Host "Stratum: $stratum"
# Write-Host "RootDelay: $rootDelay"
# Write-Host "LeapIndicator: $leapIndicator"
# Write-Host "Clock Error Bound: $clockErrorBound"
# Write-Host "Drift: $timeDifference"
# Write-Host "Drift: $sourceIP"
# Write-Host "Drift: $referenceID"
# Write-Host "Drift: $lastSyncTime"


 # Added Logging
$LogFile = 'C:\users\check.log'
$Time = Get-Date
if (!(Test-Path $LogFile)) {
    New-Item $LogFile -Value "Check Ran on $Time" -Force

} else { Add-Content -Value "Check Ran on $Time" -Path $LogFile -Force } 


