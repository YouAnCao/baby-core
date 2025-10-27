package handlers

import (
	"baby-tracker/database"
	"baby-tracker/models"
	"baby-tracker/utils"
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

type AuthHandler struct {
	JWTSecret string
}

func NewAuthHandler(jwtSecret string) *AuthHandler {
	return &AuthHandler{JWTSecret: jwtSecret}
}

// Login handles user authentication
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Get user from database
	user, err := models.GetUserByUsername(database.DB, req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "登录失败请稍后再试", http.StatusUnauthorized)
			return
		}
		http.Error(w, "登录失败请稍后再试", http.StatusInternalServerError)
		return
	}

	// If password hash is empty, this is the default user - set the password
	if user.PasswordHash == "" {
		salt, hash, err := utils.GeneratePasswordHash(req.Password)
		if err != nil {
			http.Error(w, "登录失败请稍后再试", http.StatusInternalServerError)
			return
		}
		if err := models.UpdateUserPassword(database.DB, user.ID, hash, salt); err != nil {
			http.Error(w, "登录失败请稍后再试", http.StatusInternalServerError)
			return
		}
		user.PasswordHash = hash
		user.Salt = salt
	}

	// Verify password
	if !utils.VerifyPassword(req.Password, user.Salt, user.PasswordHash) {
		http.Error(w, "登录失败请稍后再试", http.StatusUnauthorized)
		return
	}

	// Generate JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  user.ID,
		"username": user.Username,
		"exp":      time.Now().Add(time.Hour * 24 * 7).Unix(), // 7 days
	})

	tokenString, err := token.SignedString([]byte(h.JWTSecret))
	if err != nil {
		http.Error(w, "登录失败请稍后再试", http.StatusInternalServerError)
		return
	}

	// Return response
	resp := LoginResponse{
		Token: tokenString,
		User:  *user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

