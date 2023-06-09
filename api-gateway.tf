#####################################################################
### API GATEWAY RESOURCE ###
#####################################################################
resource "aws_api_gateway_rest_api" "api" {
  name = "wagonkered-website"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


#####################################################################
### API GATEWAY CUSTOM DOMAIN ###
#####################################################################
resource "aws_api_gateway_base_path_mapping" "api_custom_domain" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = format("api.%s", var.domain_name)
  stage_name  = aws_api_gateway_stage.api.stage_name
  depends_on  = [aws_api_gateway_deployment.api]
}

resource "aws_api_gateway_domain_name" "api_custom_domain" {
  domain_name              = format("api.%s", var.domain_name)
  regional_certificate_arn = aws_acm_certificate_validation.cert_validation_local_region.certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}

#####################################################################
### CONTACT REST API ### 
##################################################################### 
resource "aws_api_gateway_resource" "contact" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "contact-us"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

### POST METHOD ###
#tfsec:ignore:aws-api-gateway-no-public-access
resource "aws_api_gateway_method" "contact_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "contact_post" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.contact.invoke_arn
  depends_on              = [aws_api_gateway_method.contact_post]
}

resource "aws_api_gateway_method_response" "contact_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [aws_api_gateway_method.contact_post]
}

### OPTIONS METHOD ###
#tfsec:ignore:aws-api-gateway-no-public-access
resource "aws_api_gateway_method" "contact_options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.contact.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  type        = "MOCK"
  depends_on  = [aws_api_gateway_method.contact_options]
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_integration_response" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = aws_api_gateway_method_response.contact_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.domain_name}'"
  }

  response_templates = {
    "application/json" = "Empty"
  }
  depends_on = [aws_api_gateway_method_response.contact_options]
}

resource "aws_api_gateway_method_response" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.contact_options]
}

#####################################################################
### API GATEWAY DEPLOYMENT ###
#####################################################################

resource "aws_api_gateway_deployment" "api" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  stage_description = sha256(file("api-gateway.tf")) # Forces replacement of deployment if update to api-gateway. Otherwise it uses the same deployment, despite changes to methods (for example)
  lifecycle {
    create_before_destroy = true
  }
}

#tfsec:ignore:aws-api-gateway-enable-access-logging
#tfsec:ignore:aws-api-gateway-enable-tracing
resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "wagonkered"
}


