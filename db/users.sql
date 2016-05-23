CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  session_token VARCHAR(255) NOT NULL
);

CREATE TABLE friends (
  id INTEGER PRIMARY KEY,
  friend1_id INTEGER NOT NULL,
  friend2_id INTEGER NOT NULL,

  FOREIGN KEY(friend1_id) REFERENCES user(id),
  FOREIGN KEY(friend2_id) REFERENCES user(id)
);
