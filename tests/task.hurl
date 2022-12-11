# list tasks
GET http://0.0.0.0:8000/task/list

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

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
