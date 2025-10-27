package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

// Simple script to seed default admin user
// This is automatically handled in the auth handler on first login
// This script is for manual database setup if needed

func main() {
	db, err := sql.Open("sqlite3", "./baby_tracker.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Check if admin user exists
	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM users WHERE username = 'admin'").Scan(&count)
	if err != nil {
		log.Fatal(err)
	}

	if count > 0 {
		fmt.Println("Admin user already exists")
		return
	}

	// Insert admin user with empty password (will be set on first login)
	_, err = db.Exec(
		"INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?)",
		"admin", "", "",
	)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Admin user created successfully")
	fmt.Println("Username: admin")
	fmt.Println("Password: admin123 (set on first login)")
}

