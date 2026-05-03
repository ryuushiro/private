locals {
  subdomains = [
    "exporter.${var.student_name}",
    "prom.${var.student_name}",
    "monitoring.${var.student_name}",
    "registry.${var.student_name}",
    "staging.${var.student_name}",
    "api.staging.${var.student_name}",
    "${var.student_name}",
    "api.${var.student_name}"
  ]
}

resource "cloudflare_record" "gateway_records" {
  count   = length(local.subdomains)
  zone_id = var.cloudflare_zone_id
  name    = local.subdomains[count.index]
  value   = aws_instance.gateway.public_ip
  type    = "A"
  proxied = false # Set to false so you can use Certbot for Task 8 as required
}
