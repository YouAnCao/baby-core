package models

import (
	"database/sql"
	"time"
)

type Record struct {
	ID         int       `json:"id"`
	UserID     int       `json:"user_id"`
	RecordType string    `json:"record_type"`
	RecordTime time.Time `json:"record_time"`
	Details    string    `json:"details"`
	Notes      string    `json:"notes,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

// CreateRecord creates a new record
func CreateRecord(db *sql.DB, userID int, recordType, recordTime, details, notes string) (*Record, error) {
	result, err := db.Exec(
		"INSERT INTO records (user_id, record_type, record_time, details, notes) VALUES (?, ?, ?, ?, ?)",
		userID, recordType, recordTime, details, notes,
	)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}

	return GetRecordByID(db, int(id))
}

// GetRecordByID retrieves a record by ID
func GetRecordByID(db *sql.DB, id int) (*Record, error) {
	record := &Record{}
	err := db.QueryRow(
		"SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at FROM records WHERE id = ?",
		id,
	).Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return record, nil
}

// GetRecordsByUserAndDate retrieves all records for a user on a specific date
func GetRecordsByUserAndDate(db *sql.DB, userID int, date string) ([]*Record, error) {
	// Query for records on the specified date
	rows, err := db.Query(
		`SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at 
		FROM records 
		WHERE user_id = ? AND DATE(record_time) = ? 
		ORDER BY record_time DESC`,
		userID, date,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []*Record
	for rows.Next() {
		record := &Record{}
		err := rows.Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}

	return records, nil
}

// GetRecordsByUser retrieves all records for a user
func GetRecordsByUser(db *sql.DB, userID int, limit int) ([]*Record, error) {
	rows, err := db.Query(
		`SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at 
		FROM records 
		WHERE user_id = ? 
		ORDER BY record_time DESC 
		LIMIT ?`,
		userID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []*Record
	for rows.Next() {
		record := &Record{}
		err := rows.Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}

	return records, nil
}

// DeleteRecord deletes a record
func DeleteRecord(db *sql.DB, id, userID int) error {
	_, err := db.Exec("DELETE FROM records WHERE id = ? AND user_id = ?", id, userID)
	return err
}

