resource "cloudflare_record" "this" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  content = aws_lb.this.dns_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
