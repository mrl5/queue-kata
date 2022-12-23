use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::to_string;
use std::fmt;
use uuid::Uuid;

#[derive(sqlx::Type, Serialize, Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "task_type", rename_all = "snake_case")]
pub enum TaskType {
    TypeA,
    TypeB,
    TypeC,
}

#[derive(sqlx::Type, Serialize, Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "task_state", rename_all = "snake_case")]
pub enum TaskState {
    Pending,
    Running,
    Finished,
    Deleted,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct Task {
    pub id: Uuid,
    pub typ: TaskType,
    pub state: TaskState,
    pub created_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
    pub not_before: Option<DateTime<Utc>>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct TaskSummary {
    pub id: Uuid,
    pub typ: TaskType,
    pub state: TaskState,
}

#[derive(Serialize)]
pub struct CreatedTask {
    pub id: Uuid,
    pub state: TaskState,
}

impl fmt::Display for Task {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}",
            to_string(&self).unwrap_or_else(|_| "{}".to_owned())
        )
    }
}
