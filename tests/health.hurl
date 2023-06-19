# basic health check
GET http://0.0.0.0:8000/health

HTTP 200

[Asserts]
jsonpath "$.status" == "Healthy"
