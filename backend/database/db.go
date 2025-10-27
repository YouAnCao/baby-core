package database

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	_ "github.com/mattn/go-sqlite3"
)

var DB *sql.DB

// Initialize sets up the database connection and runs migrations
func Initialize(dbPath string) error {
	var err error
	
	// Create database directory if it doesn't exist
	dbDir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		return fmt.Errorf("failed to create database directory: %w", err)
	}

	// Open database connection
	DB, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// Run migrations
	if err := runMigrations(); err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	return nil
}

// runMigrations executes SQL migration files
func runMigrations() error {
	sqlFiles := []string{
		"../sql/001_init.sql",
		"../sql/002_records.sql",
		"../sql/003_ai_analysis.sql",
	}

	for _, file := range sqlFiles {
		content, err := os.ReadFile(file)
		if err != nil {
			// If SQL files don't exist in expected location, create tables directly
			return createTablesDirectly()
		}

		if _, err := DB.Exec(string(content)); err != nil {
			return fmt.Errorf("failed to execute %s: %w", file, err)
		}
	}

	return nil
}

// createTablesDirectly creates tables if SQL files are not found
func createTablesDirectly() error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT NOT NULL UNIQUE,
		password_hash TEXT NOT NULL,
		salt TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	
	CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
	
	CREATE TABLE IF NOT EXISTS records (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		record_type TEXT NOT NULL,
		record_time DATETIME NOT NULL,
		details TEXT NOT NULL,
		notes TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	
	CREATE INDEX IF NOT EXISTS idx_records_user_id ON records(user_id);
	CREATE INDEX IF NOT EXISTS idx_records_record_time ON records(record_time);
	CREATE INDEX IF NOT EXISTS idx_records_type ON records(record_type);
	CREATE INDEX IF NOT EXISTS idx_records_user_time ON records(user_id, record_time DESC);
	
	CREATE TABLE IF NOT EXISTS ai_analysis (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		analysis_date DATE NOT NULL,
		prompt TEXT NOT NULL,
		data_summary TEXT NOT NULL,
		ai_response TEXT NOT NULL,
		ai_provider TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	
	CREATE INDEX IF NOT EXISTS idx_ai_analysis_user_id ON ai_analysis(user_id);
	CREATE INDEX IF NOT EXISTS idx_ai_analysis_date ON ai_analysis(analysis_date DESC);
	CREATE INDEX IF NOT EXISTS idx_ai_analysis_user_date ON ai_analysis(user_id, analysis_date DESC);
	`

	_, err := DB.Exec(schema)
	return err
}

// Close closes the database connection
func Close() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}

