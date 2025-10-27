package models

import (
	"database/sql"
	"time"
)

type Record struct {
	ID         int            `json:"id"`
	UserID     int            `json:"user_id"`
	RecordType string         `json:"record_type"`
	RecordTime time.Time      `json:"record_time"`
	Details    string         `json:"details"`
	Notes      string         `json:"notes,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  sql.NullTime   `json:"deleted_at,omitempty"`
	IsDeleted  bool           `json:"is_deleted"`
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
		"SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at, deleted_at FROM records WHERE id = ?",
		id,
	).Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt, &record.DeletedAt)

	if err != nil {
		return nil, err
	}

	// Set IsDeleted flag for convenience
	record.IsDeleted = record.DeletedAt.Valid

	return record, nil
}

// GetRecordsByUserAndDate retrieves all records for a user on a specific date (including soft-deleted)
func GetRecordsByUserAndDate(db *sql.DB, userID int, date string) ([]*Record, error) {
	// Query for records on the specified date, including soft-deleted ones
	rows, err := db.Query(
		`SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at, deleted_at 
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
		err := rows.Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt, &record.DeletedAt)
		if err != nil {
			return nil, err
		}
		// Set IsDeleted flag for convenience
		record.IsDeleted = record.DeletedAt.Valid
		records = append(records, record)
	}

	return records, nil
}

// GetRecordsByUser retrieves all records for a user (including soft-deleted)
func GetRecordsByUser(db *sql.DB, userID int, limit int) ([]*Record, error) {
	rows, err := db.Query(
		`SELECT id, user_id, record_type, record_time, details, notes, created_at, updated_at, deleted_at 
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
		err := rows.Scan(&record.ID, &record.UserID, &record.RecordType, &record.RecordTime, &record.Details, &record.Notes, &record.CreatedAt, &record.UpdatedAt, &record.DeletedAt)
		if err != nil {
			return nil, err
		}
		// Set IsDeleted flag for convenience
		record.IsDeleted = record.DeletedAt.Valid
		records = append(records, record)
	}

	return records, nil
}

// SoftDeleteRecord marks a record as deleted
func SoftDeleteRecord(db *sql.DB, id, userID int) error {
	_, err := db.Exec(
		"UPDATE records SET deleted_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ? AND deleted_at IS NULL",
		id, userID,
	)
	return err
}

// RestoreRecord restores a soft-deleted record
func RestoreRecord(db *sql.DB, id, userID int) error {
	_, err := db.Exec(
		"UPDATE records SET deleted_at = NULL WHERE id = ? AND user_id = ? AND deleted_at IS NOT NULL",
		id, userID,
	)
	return err
}

// DeleteRecord permanently deletes a record (kept for compatibility, but prefer SoftDeleteRecord)
func DeleteRecord(db *sql.DB, id, userID int) error {
	_, err := db.Exec("DELETE FROM records WHERE id = ? AND user_id = ?", id, userID)
	return err
}

