variable "domain" {
  type      = string
  nullable  = false
}

variable "letsencrypt_email" {
  type      = string
  nullable  = false
}

variable "monica_db_host" {
  type      = string
  nullable  = false
}

variable "monica_db_password" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "nixos_image_id" {
  type      = string
  nullable  = false
}
