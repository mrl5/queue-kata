# /task/create
## create task
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_b"
}

HTTP/* 202

[Asserts]
jsonpath "$.task_id" exists

[Captures]
new_b_task_id: jsonpath "$.task_id"

## create postponed task
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_a",
  "not_before": "2022-12-11T16:39:04+01:00"
}

HTTP/* 202

[Asserts]
jsonpath "$.task_id" exists


# /task/list
## list tasks
GET http://0.0.0.0:8000/task/list

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.tasks[*].id" includes {{new_b_task_id}}
jsonpath "$.page" == 1
jsonpath "$.per_page" isInteger

## paginate tasks
GET http://0.0.0.0:8000/task/list?page=2&per_page=3

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.page" == 2
jsonpath "$.per_page" == 3

## filter tasks
GET http://0.0.0.0:8000/task/list?state=pending

HTTP/* 200

GET http://0.0.0.0:8000/task/list?state=running

HTTP/* 200

GET http://0.0.0.0:8000/task/list?state=finished

HTTP/* 200

GET http://0.0.0.0:8000/task/list?state=deleted

HTTP/* 200

GET http://0.0.0.0:8000/task/list?typ=type_a

HTTP/* 200

GET http://0.0.0.0:8000/task/list?typ=type_b

HTTP/* 200

GET http://0.0.0.0:8000/task/list?typ=type_c

HTTP/* 200

GET http://0.0.0.0:8000/task/list?typ=type_c&state=deleted

HTTP/* 200


# /task/:id
## get task by id
GET http://0.0.0.0:8000/task/{{new_b_task_id}}

HTTP/* 200

GET http://0.0.0.0:8000/task/00a0a0aa-a0aa-00aa-0000-0000a000a000

HTTP/* 404
