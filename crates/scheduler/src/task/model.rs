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
    Pending,
    Running,
    Finished,
    Deleted,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct Task {
    pub id: Uuid,
    pub typ: String,
    pub state: String,
    pub created_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
    pub not_before: Option<DateTime<Utc>>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, Debug)]
pub struct TaskSummary {
    pub id: Uuid,
    pub typ: String,
    pub state: String,
}

#[derive(Serialize)]
pub struct TaskSnapshot {
    pub id: Uuid,
    pub state: String,
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
