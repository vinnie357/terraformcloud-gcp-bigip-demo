# BIG-IP

# Public IP for VIP
resource "google_compute_address" "vip1" {
  name = "${var.prefix}-vip1"
}

# Forwarding rule for Public IP
resource "google_compute_forwarding_rule" "vip1" {
  name       = "${var.prefix}-forwarding-rule"
  target     = google_compute_target_instance.f5vm02.id
  ip_address = google_compute_address.vip1.address
  port_range = "1-65535"
}

resource "google_compute_target_instance" "f5vm01" {
  name     = "${var.prefix}-${var.host1_name}-ti"
  instance = google_compute_instance.f5vm01.id
}

resource "google_compute_target_instance" "f5vm02" {
  name     = "${var.prefix}-${var.host2_name}-ti"
  instance = google_compute_instance.f5vm02.id
}

# Setup Onboarding scripts
# #do_byol.json, do.json, do_bigiq.json
data template_file vm01_do_json {
  template = "${path.module}/templates/do ${var.license1 != "" ? "_byol" : "${var.bigIqLicensePool != "" ? "_bigiq" : ""}"}.json.tpl}"

  vars = {
    regKey           = var.license1
    admin_username   = var.uname
    host1            = "${var.prefix}-${var.host1_name}"
    host2            = "${var.prefix}-${var.host2_name}"
    remote_host      = "${var.prefix}-${var.host2_name}"
    dns_server       = var.dns_server
    dns_suffix       = var.dns_suffix
    ntp_server       = var.ntp_server
    timezone         = var.timezone
    bigIqLicenseType = var.bigIqLicenseType
    bigIqHost        = var.bigIqHost
    bigIqUsername    = var.bigIqUsername
    #bigIqPassword      = var.bigIqPassword
    #set in onboarding script
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  }
}

data template_file vm02_do_json {
  template = "${path.module}/templates/do ${var.license1 != "" ? "_byol" : "${var.bigIqLicensePool != "" ? "_bigiq" : ""}"}.json.tpl}"

  vars = {
    regKey           = var.license2
    admin_username   = var.uname
    host1            = "${var.prefix}-${var.host1_name}"
    host2            = "${var.prefix}-${var.host2_name}"
    remote_host      = google_compute_instance.f5vm01.network_interface.1.network_ip
    dns_server       = var.dns_server
    dns_suffix       = var.dns_suffix
    ntp_server       = var.ntp_server
    timezone         = var.timezone
    bigIqLicenseType = var.bigIqLicenseType
    bigIqHost        = var.bigIqHost
    bigIqUsername    = var.bigIqUsername
    #bigIqPassword      = var.bigIqPassword
    #set in onboarding script
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  }
}
data template_file vm01_onboard {
  template = "${path.module}/templates/onboard.sh.tpl"

  vars = {
    uname          = var.uname
    usecret        = var.usecret
    ksecret        = var.ksecret
    gcp_project_id = var.gcp_project_id
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    CF_URL         = var.CF_URL
    onboard_log    = var.onboard_log
    DO_Document    = data.template_file.vm01_do_json.rendered
    AS3_Document   = ""
    TS_Document    = data.template_file.ts_json.rendered
    CFE_Document   = data.template_file.vm01_cfe_json.rendered
  }
}
data template_file vm02_onboard {
  template = "${path.module}/templates/onboard.sh.tpl"

  vars = {
    uname          = var.uname
    usecret        = var.usecret
    ksecret        = var.ksecret
    gcp_project_id = var.gcp_project_id
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    CF_URL         = var.CF_URL
    onboard_log    = var.onboard_log
    DO_Document    = data.template_file.vm02_do_json.rendered
    AS3_Document   = data.template_file.as3_json.rendered
    TS_Document    = data.template_file.ts_json.rendered
    CFE_Document   = data.template_file.vm02_cfe_json.rendered
  }
}
data template_file as3_json {
  template = "${path.module}/templates/as3.json.tpl"

  vars = {
    gcp_region = var.gcp_region
    #publicvip  = "0.0.0.0"
    publicvip  = google_compute_address.vip1.address
    privatevip = var.alias_ip_range
    uuid       = uuid()
  }
}
data template_file ts_json {
  template = "${path.module}/templates/ts.json.tpl"

  vars = {
    gcp_project_id = var.gcp_project_id
    svc_acct       = var.svc_acct
    privateKeyId   = var.privateKeyId
  }
}
data template_file vm01_cfe_json {
  template = "${path.module}/templates/cfe.json.tpl"

  vars = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    managed_route1          = var.managed_route1
    remote_selfip           = ""
  }
}
data template_file vm02_cfe_json {
  template = "${path.module}/templates/cfe.json.tpl"

  vars = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    managed_route1          = var.managed_route1
    remote_selfip           = google_compute_instance.f5vm01.network_interface.0.network_ip
  }
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "f5vm01" {
  depends_on     = [google_compute_subnetwork.vpc_network_mgmt_sub, google_compute_subnetwork.vpc_network_int_sub, google_compute_subnetwork.vpc_network_ext_sub]
  name           = "${var.prefix}-${var.host1_name}"
  machine_type   = var.bigipMachineType
  zone           = var.gcp_zone
  can_ip_forward = true

  labels = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }

  tags = ["appfw-${var.prefix}", "mgmtfw-${var.prefix}"]

  boot_disk {
    initialize_params {
      image = var.customImage != "" ? var.customImage : var.image_name
      size  = "128"
    }
  }

  network_interface {
    network    = var.extVpc
    subnetwork = var.extSubnet
    access_config {
    }
  }

  network_interface {
    network    = var.mgmtVpc
    subnetwork = var.mgmtSubnet
    access_config {
    }
  }

  network_interface {
    network    = var.intVpc
    subnetwork = var.intSubnet
  }

  metadata = {
    ssh-keys               = "${var.uname}:${var.gceSshPubKey}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : data.template_file.vm01_onboard.rendered
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "f5vm02" {
  depends_on     = [google_compute_subnetwork.vpc_network_mgmt_sub, google_compute_subnetwork.vpc_network_int_sub, google_compute_subnetwork.vpc_network_ext_sub]
  name           = "${var.prefix}-${var.host2_name}"
  machine_type   = var.bigipMachineType
  zone           = var.gcp_zone
  can_ip_forward = true

  labels = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }

  tags = ["appfw-${var.prefix}", "mgmtfw-${var.prefix}"]

  boot_disk {
    initialize_params {
      image = var.customImage != "" ? var.customImage : var.image_name
      size  = "128"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network_ext.name
    subnetwork = google_compute_subnetwork.vpc_network_ext_sub.name
    access_config {
    }
    alias_ip_range {
      ip_cidr_range = var.alias_ip_range
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network_mgmt.name
    subnetwork = google_compute_subnetwork.vpc_network_mgmt_sub.name
    access_config {
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network_int.name
    subnetwork = google_compute_subnetwork.vpc_network_int_sub.name
  }

  metadata = {
    ssh-keys               = "${var.uname}:${var.gceSshPubKey}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : data.template_file.vm02_onboard.rendered
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }
}

# # Troubleshooting - create local output files
# resource "local_file" "onboard_file" {
#   content  = local.vm01_onboard
#   filename = "${path.module}/vm01_onboard.tpl_data.json"
# }