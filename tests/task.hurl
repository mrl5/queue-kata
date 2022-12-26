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
jsonpath "$.tasks[*].id" includes {{new_c_task_id}}
jsonpath "$.tasks[*].id" includes {{new_b_task_id}}
jsonpath "$.tasks[*].id" includes {{new_a_task_id}}
jsonpath "$.page" == 1
jsonpath "$.per_page" isInteger

## paginate tasks
GET http://0.0.0.0:8000/task/list?page=2&per_page=3

HTTP/* 200

[Asserts]
jsonpath "$.tasks[3]" not exists
jsonpath "$.page" == 2
jsonpath "$.per_page" == 3

## filter tasks

GET http://0.0.0.0:8000/task/list?state=pending

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=deleted

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection

GET http://0.0.0.0:8000/task/list?state=running

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
jsonpath "$.tasks[*].id" not includes {{new_c_task_id}}
jsonpath "$.tasks[*].id" not includes {{new_b_task_id}}
jsonpath "$.tasks[*].id" includes {{new_a_task_id}}

GET http://0.0.0.0:8000/task/list?typ=type_b

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.tasks[*].id" not includes {{new_c_task_id}}
jsonpath "$.tasks[*].id" includes {{new_b_task_id}}
jsonpath "$.tasks[*].id" not includes {{new_a_task_id}}

GET http://0.0.0.0:8000/task/list?typ=type_c

HTTP/* 200

[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.tasks[*].id" includes {{new_c_task_id}}
jsonpath "$.tasks[*].id" not includes {{new_b_task_id}}
jsonpath "$.tasks[*].id" not includes {{new_a_task_id}}

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

DELETE http://0.0.0.0:8000/task/{{new_b_task_id}}

HTTP/* 404

GET http://0.0.0.0:8000/task/00a0a0aa-a0aa-00aa-0000-0000a000a000

HTTP/* 404
