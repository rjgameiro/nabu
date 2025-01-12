
output "acme_registration" {
  value = acme_registration.letsencrypt_registration.id
}

output "certificate_not_after" {
  value = acme_certificate.letsencrypt_certificate.certificate_not_after
}

output "certificate_domain" {
  value = acme_certificate.letsencrypt_certificate.certificate_domain
}

output "certificate_common_name" {
  value = acme_certificate.letsencrypt_certificate.common_name
}

output "certificate_alternate_names" {
  value = acme_certificate.letsencrypt_certificate.subject_alternative_names
}

output "certificate_url" {
  value = acme_certificate.letsencrypt_certificate.certificate_url
}
