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
            # @{
            #     Name = "ASG-Name"
            #     Value = $asgName
            # }
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
            # @{
            #     Name = "ASG-Name"
            #     Value = $asgName
            # }
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
            # @{
            #     Name = "ASG-Name"
            #     Value = $asgName
            # }
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
    }
)
