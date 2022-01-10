variable "domain" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "letsencrypt_email" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "nixos_image_id" {
  type      = string
  nullable  = false
  sensitive = true
}
