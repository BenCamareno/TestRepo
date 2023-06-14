$status          = Get-Service w32time -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
$ReferenceIP     = [regex]::Match($ntpSyncStatus.Dimensions.ReferenceId, "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}").Value.Replace('.', '')
$SourceIP        = $ntpSyncStatus.Dimensions.Source.Split(',')[0].Trim().Replace('.', '')
$leapIndicator   = [int]$ntpSyncStatus.metrics.LeapIndicator
$rootDispersion  = [double]::Parse($ntpSyncStatus.metrics.RootDispersion.Trim('s')).ToString("##.###############")
$rootDelay       = [double]::Parse($ntpSyncStatus.metrics.RootDelay.Trim('s')).ToString("##.###############")
$precision       = [int]$ntpSyncStatus.metrics.Precision
$pollInterval    = ([int]$ntpSyncStatus.metrics.PollInterval).ToString("##.###############")
$stratum         = [int]$ntpSyncStatus.metrics.Stratum
$LastSyncAgo     = ((New-TimeSpan -Start ($ntpSyncStatus.metrics.LastSyncTime) -End (Get-Date)).TotalSeconds).ToString("##.###############")
$upstreamTime    = & w32tm /stripchart /computer:169.254.169.123 /samples:1 /dataonly
$match           = [regex]::Match($upstreamTime, '(\d{2}:\d{2}:\d{2}),\s+([-+]?\d+\.\d+s)')
$TimeDrift       = ([double]$match.Groups[2].Value.Trim('s')).ToString("##.###############")
$clockErrorBound = [double]$timeDifference + (0.5 * $rootDelay + $rootDispersion).ToString("##.###############")
$NumberOfPeers   = (w32tm /query /peers | Select-String -Pattern "Peers" | ForEach-Object { ($_ -split ' ')[1] })
$instanceId      = Invoke-WebRequest -Uri 169.254.169.254/latest/meta-data/instance-id/ -UseBasicParsing | Select-Object -Expand Content
$hostname        = hostname
$accountId       = (Invoke-WebRequest -Uri 169.254.169.254/latest/dynamic/instance-identity/document -UseBasicParsing | ConvertFrom-Json).accountId
