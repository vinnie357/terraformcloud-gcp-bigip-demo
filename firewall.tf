# firewall
resource google_compute_firewall default-allow-internal-mgmt {
  name    = "${var.prefix}-default-allow-internal-mgmt"
  network = google_compute_network.vpc_network_mgmt.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.10.0/24"]
}
resource google_compute_firewall default-allow-internal-ext {
  name    = "${var.prefix}-default-allow-internal-ext"
  network = google_compute_network.vpc_network_ext.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.30.0/24"]
}
resource google_compute_firewall default-allow-internal-int {
  name    = "${var.prefix}-default-allow-internal-int"
  network = google_compute_network.vpc_network_int.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  priority = "65534"

  source_ranges = ["10.0.20.0/24"]
}
resource google_compute_firewall allow-internal-egress {
  name           = "${var.prefix}-allow-internal-egress"
  network        = google_compute_network.vpc_network_int.name
  direction      = "EGRESS"
  enable_logging = true

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  priority = "65533"

  destination_ranges = ["10.0.20.0/24"]
}

resource google_compute_firewall mgmt {
  name    = "${var.prefix}-mgmt"
  network = google_compute_network.vpc_network_mgmt.name
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  source_ranges = var.adminSrcAddr
}
resource google_compute_firewall app {
  name    = "${var.prefix}-app-vpn"
  network = google_compute_network.vpc_network_ext.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }

  source_ranges = var.adminSrcAddr
}