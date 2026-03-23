output "nat_public_ip" {
  description = "Public IP of the NAT instance"
  value       = yandex_compute_instance.nat.network_interface[0].nat_ip_address
}

output "public_vm_public_ip" {
  description = "Public IP of a public VM"
  value       = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
}

output "public_vm_internal_ip" {
  description = "Internal IP of a public VM"
  value       = yandex_compute_instance.public_vm.network_interface[0].ip_address
}

output "private_vm_internal_ip" {
  description = "Internal IP of a private VM"
  value       = yandex_compute_instance.private_vm.network_interface[0].ip_address
}

output "ssh_to_public_vm" {
  description = "Command to connect to a public VM"
  value       = "ssh ubuntu@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}"
}

output "ssh_to_private_vm_via_jump" {
  description = "Command for connecting to a private VM via jump-host"
  value       = "ssh -J ubuntu@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address} ubuntu@${yandex_compute_instance.private_vm.network_interface[0].ip_address}"
}

output "image_spqr_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.backet.bucket}/${yandex_storage_object.image.key}"
}

output "image_url" {
  value = local.image_url
}

output "nlb_ip" {
  description = "Public IP balancer"
  value = one([
    for spec in one([
      for l in yandex_lb_network_load_balancer.lamp-nlb.listener : l
      if l.name == "http-listener"
    ]).external_address_spec : spec.address
  ])
}