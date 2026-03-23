variable "yc_token" {
  description = "Yandex Cloud OAuth token (or IAM token)"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key" {
  description = "Path to your SSH public key file"
  type        = string
}

variable "NAT_image_id" {
  description = "Image ID for NAT VM"
  type        = string
  default     = "fd80mrhj8fl2oe87o4e1"
}

variable "ubuntu_image_id" {
  description = "Image ID for public/private VMs"
  type        = string
  default     = "fd8e5jmcvep85j33nt0e"
}

variable "backet" {
  description = "Backet name"
  type = string
  default = "evgeny20032026"
}

variable "image_key" {
  description = "Name image key"
  type = string
  default = "spqr.jpg"
}

variable "image_source" {
  description = "Source image"
  type = string
  default = "./spqr.jpg"
}

variable "group_lamp_image_id" {
  description = "Image ID for group lamp"
  type = string
  default = "fd827b91d99psvq5fjit"
}

variable "service_account_id" {
  description = "ID account"
  type = string
}
