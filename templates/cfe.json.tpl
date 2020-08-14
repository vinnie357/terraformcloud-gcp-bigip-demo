{
    "class": "Cloud_Failover",
    "environment": "gcp",
    "externalStorage": {
        "scopingTags": {
            "f5_cloud_failover_label": "${f5_cloud_failover_label}"
        }
    },
    "failoverAddresses": {
        "enabled": true,
        "scopingTags": {
            "f5_cloud_failover_label": "${f5_cloud_failover_label}"
        }
    },
    "failoverRoutes": {
        "enabled": true,
        "scopingTags": {
            "f5_cloud_failover_label": "${f5_cloud_failover_label}"
        },
        "scopingAddressRanges": [
            {
                "range": "${managed_route1}"
            }
        ],
        "defaultNextHopAddresses": {
            "discoveryType": "static",
            "items": [
                "$${local_selfip_ext}",
                "${remote_selfip}"
            ]
        }
    }
  }