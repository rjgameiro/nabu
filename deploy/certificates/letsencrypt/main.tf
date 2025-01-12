
provider "acme" {
  server_url = format("https://acme%s-v02.api.letsencrypt.org/directory", local.config["letsencrypt_staging"] ? "-staging" : "")
}

data "linode_domain" "domain" {
  domain = var.domain
}

resource "linode_domain_record" "public_name_to_ipv4" {
  domain_id   = data.linode_domain.domain.id
  name        = format("%s%s", terraform.workspace != "release" ? "${terraform.workspace}." : "", var.project)
  record_type = "TXT"
  ttl_sec     = 28800
  target      = "${var.project} ${terraform.workspace}: automated certificate placeholder"
}

resource "tls_private_key" "account_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "acme_registration" "letsencrypt_registration" {
  account_key_pem = tls_private_key.account_private_key.private_key_pem
  email_address   = var.owner
}

resource "acme_certificate" "letsencrypt_certificate" {
  account_key_pem           = acme_registration.letsencrypt_registration.account_key_pem
  common_name               = format("*.%s%s.%s", terraform.workspace != "release" ? "${terraform.workspace}." : "", var.project, var.domain)
  subject_alternative_names = [ format("%s%s.%s", terraform.workspace != "release" ? "${terraform.workspace}." : "", var.project, var.domain) ]
  min_days_remaining        = 20
  dns_challenge {
    provider = var.dns_provider
  }
}

resource "terraform_data" "certificate_full_chain_1password" {
  triggers_replace = [
    sha256(acme_certificate.letsencrypt_certificate.certificate_pem)
  ]
  provisioner "local-exec" {
    command = format("op item edit \"%s SSL Certificates\" \"%s.full chain[concealed]=%s%s\"", var.project, terraform.workspace, acme_certificate.letsencrypt_certificate.certificate_pem, acme_certificate.letsencrypt_certificate.issuer_pem)
  }
  depends_on = [
    acme_certificate.letsencrypt_certificate
  ]
}

resource "terraform_data" "certificate_private_key_1password" {
  triggers_replace = [
    sha256(acme_certificate.letsencrypt_certificate.private_key_pem)
  ]
  provisioner "local-exec" {
    command = format("op item edit \"%s SSL Certificates\" \"%s.private key[concealed]=%s\"", var.project, terraform.workspace, acme_certificate.letsencrypt_certificate.private_key_pem)
  }
  depends_on = [
    acme_certificate.letsencrypt_certificate,
    terraform_data.certificate_full_chain_1password
  ]
}
