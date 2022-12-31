use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::to_string;
use std::fmt;
use strum::Display;
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug, Display)]
#[strum(serialize_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum TaskType {
    TypeA,
    TypeB,
    TypeC,
}

#[derive(Serialize, Deserialize, Debug, Display)]
#[strum(serialize_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum TaskState {
    Created,
    Pending,
    Deferred,
    Deleted,
    Processing,
    Failed,
    Done,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct Task {
    pub id: Option<Uuid>,
    pub typ: Option<String>,
    pub state: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub not_before: Option<DateTime<Utc>>,
    pub inactive_since: Option<DateTime<Utc>>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct TaskSummary {
    pub id: Uuid,
    pub typ: String,
    pub state: Option<String>,
}

#[derive(Serialize)]
pub struct TaskSnapshot {
    pub id: Option<Uuid>,
    pub state: Option<String>,
}

#[derive(Serialize)]
pub struct TaskId {
    pub id: Option<Uuid>,
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
