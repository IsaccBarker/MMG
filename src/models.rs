use diesel::prelude::*;

#[derive(Queryable)]
pub struct Post {
    pub uuid: i32,
    pub title: String,
    pub description: String,
    pub filepath: String,
    pub published: bool,
}
