terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

# ──────────────────────────────────────────────
# Subnets
# ──────────────────────────────────────────────
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
}

# ──────────────────────────────────────────────
# Route table
# ──────────────────────────────────────────────
resource "yandex_vpc_route_table" "private" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

# ──────────────────────────────────────────────
# Security groups
# ──────────────────────────────────────────────
resource "yandex_vpc_security_group" "nat" {
  name       = "nat-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "ANY"
    description    = "Allow all from private subnet"
    v4_cidr_blocks = ["192.168.20.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "public_vm" {
  name       = "public-vm-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "NLB health check"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 80
  } 

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "private_vm" {
  name       = "private-vm-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from public subnet"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ──────────────────────────────────────────────
# NAT-instance
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.NAT_image_id
      type = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    ip_address         = "192.168.10.254"
    nat                = true
    security_group_ids = [yandex_vpc_security_group.nat.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

# ──────────────────────────────────────────────
# Public VM
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      type = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.public_vm.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

# ──────────────────────────────────────────────
# Private VM
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      type = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.private_vm.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}
