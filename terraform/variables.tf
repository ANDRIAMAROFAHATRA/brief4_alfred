variable "rg" {
  default = "sanlab02"
}

variable "location" {
  default = "francecentral"
}

variable "subdomain-prefix" {
  default = "votingappsan"
}

data "cloudinit_config" "cloud-init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("cloud-init.yml", {REDIS_HOST = azurerm_redis_cache.redis.hostname,
                                                   REDIS_PWD = azurerm_redis_cache.redis.primary_access_key})
  }
}
