// @generated automatically by Diesel CLI.

diesel::table! {
    posts (uuid) {
        uuid -> Int4,
        title -> Varchar,
        description -> Text,
        filepath -> Text,
        published -> Bool,
    }
}
