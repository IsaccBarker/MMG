CREATE TABLE posts (
  uuid SERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  description TEXT NOT NULL,
  filepath TEXT NOT NULL,
  published BOOLEAN NOT NULL DEFAULT FALSE
)
