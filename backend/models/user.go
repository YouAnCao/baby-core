package models

import (
	"database/sql"
	"time"
)

type User struct {
	ID           int       `json:"id"`
	Username     string    `json:"username"`
	PasswordHash string    `json:"-"`
	Salt         string    `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// GetUserByUsername retrieves a user by username
func GetUserByUsername(db *sql.DB, username string) (*User, error) {
	user := &User{}
	err := db.QueryRow(
		"SELECT id, username, password_hash, salt, created_at, updated_at FROM users WHERE username = ?",
		username,
	).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Salt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return user, nil
}

// CreateUser creates a new user
func CreateUser(db *sql.DB, username, passwordHash, salt string) (*User, error) {
	result, err := db.Exec(
		"INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?)",
		username, passwordHash, salt,
	)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}

	return GetUserByID(db, int(id))
}

// GetUserByID retrieves a user by ID
func GetUserByID(db *sql.DB, id int) (*User, error) {
	user := &User{}
	err := db.QueryRow(
		"SELECT id, username, password_hash, salt, created_at, updated_at FROM users WHERE id = ?",
		id,
	).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Salt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return user, nil
}

// UpdateUserPassword updates a user's password
func UpdateUserPassword(db *sql.DB, userID int, passwordHash, salt string) error {
	_, err := db.Exec(
		"UPDATE users SET password_hash = ?, salt = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		passwordHash, salt, userID,
	)
	return err
}

