# list tasks
GET http://0.0.0.0:8000/task/list

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.page" == 1
jsonpath "$.per_page" isInteger

# paginate tasks
GET http://0.0.0.0:8000/task/list?page=2&per_page=3

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.page" == 2
jsonpath "$.per_page" == 3

# create task
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_b"
}

HTTP/* 202

[Asserts]
jsonpath "$.task_id" exists

# create postponed task
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_b",
  "not_before": "2022-12-11T16:39:04+01:00"
}

HTTP/* 202

[Asserts]
jsonpath "$.task_id" exists
