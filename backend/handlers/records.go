package handlers

import (
	"baby-tracker/database"
	"baby-tracker/middleware"
	"baby-tracker/models"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type RecordsHandler struct{}

func NewRecordsHandler() *RecordsHandler {
	return &RecordsHandler{}
}

type CreateRecordRequest struct {
	RecordType string `json:"record_type"`
	RecordTime string `json:"record_time"`
	Details    string `json:"details"`
	Notes      string `json:"notes,omitempty"`
}

type GetRecordsResponse struct {
	Records []*models.Record `json:"records"`
	Date    string           `json:"date"`
}

// CreateRecord handles creating a new record
func (h *RecordsHandler) CreateRecord(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateRecordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.RecordType == "" || req.RecordTime == "" || req.Details == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	// Validate record time format
	if _, err := time.Parse(time.RFC3339, req.RecordTime); err != nil {
		http.Error(w, "Invalid record_time format, expected RFC3339", http.StatusBadRequest)
		return
	}

	// Create record
	record, err := models.CreateRecord(database.DB, userID, req.RecordType, req.RecordTime, req.Details, req.Notes)
	if err != nil {
		http.Error(w, "Failed to create record", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(record)
}

// GetRecords handles retrieving records for a specific date
func (h *RecordsHandler) GetRecords(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get date from query parameter, default to today
	date := r.URL.Query().Get("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}

	// Validate date format
	if _, err := time.Parse("2006-01-02", date); err != nil {
		http.Error(w, "Invalid date format, expected YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	// Get records
	records, err := models.GetRecordsByUserAndDate(database.DB, userID, date)
	if err != nil {
		http.Error(w, "Failed to get records", http.StatusInternalServerError)
		return
	}

	// Return empty array if no records found
	if records == nil {
		records = []*models.Record{}
	}

	resp := GetRecordsResponse{
		Records: records,
		Date:    date,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// GetSummary is a placeholder for future AI analysis
func (h *RecordsHandler) GetSummary(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Placeholder response
	resp := map[string]interface{}{
		"message": "AI analysis feature coming soon",
		"user_id": userID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// DeleteRecord handles deleting a record
func (h *RecordsHandler) DeleteRecord(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get record ID from query parameter
	recordIDStr := r.URL.Query().Get("id")
	if recordIDStr == "" {
		http.Error(w, "Missing record ID", http.StatusBadRequest)
		return
	}

	var recordID int
	if _, err := fmt.Sscanf(recordIDStr, "%d", &recordID); err != nil {
		http.Error(w, "Invalid record ID", http.StatusBadRequest)
		return
	}

	// Delete record
	if err := models.DeleteRecord(database.DB, recordID, userID); err != nil {
		http.Error(w, "Failed to delete record", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

