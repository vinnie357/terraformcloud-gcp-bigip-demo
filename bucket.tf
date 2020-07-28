resource google_storage_bucket bigip-ha {
  name     = "${var.prefix}-bigip-storage"
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  labels = {
      f5_cloud_failover_label = var.f5_cloud_failover_label
  }
  force_destroy = true
}
