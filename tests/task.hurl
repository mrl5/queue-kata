# /task/create
## create task

POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_c"
}

HTTP/* 202

[Asserts]
jsonpath "$.id" exists

[Captures]
new_c_task_id: jsonpath "$.id"

POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_b"
}

HTTP/* 202

[Asserts]
jsonpath "$.id" exists

[Captures]
new_b_task_id: jsonpath "$.id"

## create postponed task
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_a",
  "not_before": "{{tomorrow}}"
}

HTTP/* 202

[Asserts]
jsonpath "$.id" exists

[Captures]
new_a_task_id: jsonpath "$.id"

POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_c"
}
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_b"
}
POST http://0.0.0.0:8000/task/create
{
  "task_type": "type_a"
}


# /task/list
## list tasks
GET http://0.0.0.0:8000/task/list

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.per_page" isInteger

## paginate tasks
GET http://0.0.0.0:8000/task/list?per_page=2

HTTP/* 200

[Asserts]
jsonpath "$.tasks[2]" not exists
jsonpath "$.per_page" == 2
jsonpath "$.anchor" exists

[Captures]
anchor: jsonpath "$.anchor"

GET http://0.0.0.0:8000/task/list?per_page=2&anchor={{anchor}}

HTTP/* 200

[Asserts]
jsonpath "$.tasks[2]" not exists
jsonpath "$.per_page" == 2

## filter tasks

GET http://0.0.0.0:8000/task/list?state=pending

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=deferred

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=deleted

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=processing

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=failed

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=done

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?typ=type_a

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?typ=type_b

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?typ=type_c

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?typ=type_c&state=deleted

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection


# /task/:id
## get task by id
GET http://0.0.0.0:8000/task/{{new_b_task_id}}

HTTP/* 200

[Asserts]
jsonpath "$.id" == {{new_b_task_id}}

GET http://0.0.0.0:8000/task/00a0a0aa-a0aa-00aa-0000-0000a000a000

HTTP/* 404

## delete task by id
DELETE http://0.0.0.0:8000/task/{{new_b_task_id}}

HTTP/* 200

[Asserts]
jsonpath "$.id" == {{new_b_task_id}}
jsonpath "$.state" == "deleted"
jsonpath "$.inactive_since" exists

[Captures]
b_task_inactive_since: jsonpath "$.inactive_since"

DELETE http://0.0.0.0:8000/task/{{new_b_task_id}}

HTTP/* 200

[Asserts]
jsonpath "$.id" == {{new_b_task_id}}
jsonpath "$.state" == "deleted"
jsonpath "$.inactive_since" == {{b_task_inactive_since}}

DELETE http://0.0.0.0:8000/task/00a0a0aa-a0aa-00aa-0000-0000a000a000

HTTP/* 404
