# scheduler kata

## requirements

Expose an API that can:
* Create a task of a specific type and execution time, returning the task's ID
* Show a list of tasks, filterable by their state (whatever states you define) and/or their task type
* Show a task based on its ID
* Delete a task based on its ID
* The tasks must be persisted into some external data store (your choice).
* Process each task only once and only at/after their specified execution time.
* Support running multiple instances of your code in parallel.
