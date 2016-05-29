CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  session_token VARCHAR(255) NOT NULL
);

CREATE TABLE friendships (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  friend_id INTEGER NOT NULL,
  status VARCHAR(255) NOT NULL,

  FOREIGN KEY(user_id) REFERENCES user(id),
  FOREIGN KEY(friend_id) REFERENCES user(id)
);
