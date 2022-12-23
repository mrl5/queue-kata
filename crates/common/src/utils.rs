use serde::Deserialize;

pub const MAX_PER_PAGE: usize = 100;
pub const DEFAULT_PER_PAGE: usize = 10;

#[derive(Deserialize)]
pub struct Pagination {
    pub page: Option<usize>,
    pub per_page: Option<usize>,
}

pub fn paginate(pagination: Pagination) -> (usize, usize, usize) {
    let page = pagination.page.unwrap_or(1);
    let per_page = pagination
        .per_page
        .unwrap_or(DEFAULT_PER_PAGE)
        .clamp(1, MAX_PER_PAGE);
    let offset = (page.max(1) - 1) * per_page;
    (per_page, offset, page)
}
