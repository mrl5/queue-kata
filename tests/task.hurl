# list tasks
GET http://0.0.0.0:8000/task/list

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
