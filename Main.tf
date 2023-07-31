resource "aws_api_gateway_rest_api" "Rest-API" {
  name = "DeveloperAPI"
  endpoint_configuration {
    types = [var.types]
  }
}

resource "aws_api_gateway_resource" "ASPENServices" {
  parent_id   = aws_api_gateway_rest_api.Rest-API.root_resource_id
  path_part   = "ASPENServices"
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
}

resource "aws_api_gateway_resource" "rest" {
  parent_id   = aws_api_gateway_resource.ASPENServices.id
  path_part   = "rest"
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
}

#proxy wild card resource
resource "aws_api_gateway_resource" "proxy" {
  parent_id   = aws_api_gateway_resource.rest.id
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "HouseholdSearch" {
  parent_id   = aws_api_gateway_resource.rest.id
  path_part   = "householdSearch"
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
}

resource "aws_api_gateway_method" "HouseholdSearch" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.HouseholdSearch.id
  rest_api_id   = aws_api_gateway_rest_api.Rest-API.id
}

resource "aws_api_gateway_method" "proxy" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.proxy.id
  rest_api_id   = aws_api_gateway_rest_api.Rest-API.id
  request_parameters = {
    "method.request.path.proxy" = true
  }

}


resource "aws_api_gateway_integration" "HouseholdSearch" {
  http_method = aws_api_gateway_method.HouseholdSearch.http_method
  resource_id = aws_api_gateway_resource.HouseholdSearch.id
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.Rest-API.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  type                    = "HTTP_PROXY"
  uri                     = "https://nr2fqymeic.execute-api.us-west-2.amazonaws.com/test/{proxy}"
  integration_http_method = "GET"

  cache_key_parameters = ["method.request.path.proxy"]

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method_response" "HTTP_OK" {
  resource_id = aws_api_gateway_resource.HouseholdSearch.id
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
  http_method = aws_api_gateway_method.HouseholdSearch.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "HouseholdSearch" {
  resource_id = aws_api_gateway_resource.HouseholdSearch.id
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id
  http_method = aws_api_gateway_method.HouseholdSearch.http_method
  status_code = aws_api_gateway_method_response.HTTP_OK.status_code
}
resource "aws_api_gateway_deployment" "Non_prod" {
  depends_on  = [aws_api_gateway_rest_api.Rest-API]
  rest_api_id = aws_api_gateway_rest_api.Rest-API.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "Non-Prod" {
  deployment_id = aws_api_gateway_deployment.Non_prod.id
  rest_api_id   = aws_api_gateway_rest_api.Rest-API.id
  stage_name    = "DEV01"
}
