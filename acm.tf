resource "aws_acm_certificate" "cert" {
  provider                  = aws.acm_provider
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}", var.domain_name_dot_com, "*.${var.domain_name_dot_com}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = concat([for record in aws_route53_record.certification_validation : record.fqdn], [for record in aws_route53_record.certification_validation_dot_com : record.fqdn])
}
resource "aws_acm_certificate" "cert_local_region" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation_local_region" {
  certificate_arn         = aws_acm_certificate.cert_local_region.arn
  validation_record_fqdns = [for record in aws_route53_record.certification_validation_local_region : record.fqdn]
}

