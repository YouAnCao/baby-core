package utils

import (
	"crypto/md5"
	"crypto/rand"
	"encoding/hex"
	"fmt"
)

// GenerateSalt generates a random salt
func GenerateSalt() (string, error) {
	salt := make([]byte, 16)
	_, err := rand.Read(salt)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(salt), nil
}

// HashPassword hashes a password with salt using MD5
func HashPassword(password, salt string) string {
	hasher := md5.New()
	hasher.Write([]byte(password + salt))
	return hex.EncodeToString(hasher.Sum(nil))
}

// VerifyPassword verifies if a password matches the hash
func VerifyPassword(password, salt, hash string) bool {
	return HashPassword(password, salt) == hash
}

// GeneratePasswordHash generates both salt and hash for a new password
func GeneratePasswordHash(password string) (salt, hash string, err error) {
	salt, err = GenerateSalt()
	if err != nil {
		return "", "", fmt.Errorf("failed to generate salt: %w", err)
	}
	hash = HashPassword(password, salt)
	return salt, hash, nil
}

