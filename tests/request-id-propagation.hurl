# respond with x-request-id
GET http://0.0.0.0:8000/health

HTTP/* 200

[Asserts]
header "x-request-id" exists
header "x-request-id" matches "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"


# propagate x-request-id
GET http://0.0.0.0:8000/health
x-request-id: foo

HTTP/* 200

[Asserts]
header "x-request-id" == "foo"
