# ──────────────────────────────────────────────
# Storage bucket
# ──────────────────────────────────────────────
resource "yandex_storage_bucket" "backet" {
  bucket = var.backet
  folder_id = var.folder_id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.backet.id
  key    = var.image_key
  source = var.image_source
  acl    = "public-read"
  content_type = "image/jpeg"
  
}

locals {
  image_url = "https://${yandex_storage_bucket.backet.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}"
}

# ──────────────────────────────────────────────
# Group VM
# ──────────────────────────────────────────────
resource "yandex_compute_instance_group" "lamp-public-group" {
  name               = "lamp-public"
  service_account_id = var.service_account_id

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = var.group_lamp_image_id
        type     = "network-hdd"
        size     = 10
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.main.id
      subnet_ids         = [yandex_vpc_subnet.public.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.public_vm.id]
    }

    metadata    = {
      ssh-keys  = "ubuntu:${var.ssh_public_key}"
      user-data = <<-EOF
        #!/bin/bash
        apt-get update -y
        apt-get install -y apache2
        systemctl enable apache2
        systemctl start apache2
        cat > /var/www/html/index.html <<HTML
        <html>
          <body>
            <h1>Hello from LAMP!</h1>
            <img src="${local.image_url}" alt="Image from bucket" />
          </body>
        </html>
        HTML
      EOF
    }
  }

  load_balancer {
    target_group_name = "lamp-target-group"
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3

    http_options {
      port = 80
      path = "/"
    }
  }
}

# ──────────────────────────────────────────────
# Netork load balancer
# ──────────────────────────────────────────────
resource "yandex_lb_network_load_balancer" "lamp-nlb" {
  name = "lamp-nlb"
  type = "external"

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp-public-group.load_balancer[0].target_group_id

    healthcheck {
      name = "http-hc"
      interval              = 10
      timeout               = 5
      healthy_threshold     = 2
      unhealthy_threshold   = 3

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}