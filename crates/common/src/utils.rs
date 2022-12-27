use serde::Deserialize;
use uuid::Uuid;

pub const MAX_PER_PAGE: usize = 100;
pub const DEFAULT_PER_PAGE: usize = 10;

#[derive(Deserialize)]
pub struct Pagination {
    pub anchor: Option<Uuid>,
    pub per_page: Option<usize>,
}

pub fn paginate(pagination: Pagination) -> (usize, Option<Uuid>) {
    let per_page = pagination
        .per_page
        .unwrap_or(DEFAULT_PER_PAGE)
        .clamp(1, MAX_PER_PAGE);
    (per_page, pagination.anchor)
}
