package main

import (
	"baby-tracker/config"
	"baby-tracker/database"
	"baby-tracker/handlers"
	"baby-tracker/middleware"
	"log"
	"net/http"
	"path/filepath"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	if err := database.Initialize(cfg.DBPath); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.Close()

	log.Println("Database initialized successfully")

	// Create router
	r := chi.NewRouter()

	// Middleware
	r.Use(chiMiddleware.Logger)
	r.Use(chiMiddleware.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:*", "http://127.0.0.1:*", "http://*", "https://*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(cfg.JWTSecret)
	recordsHandler := handlers.NewRecordsHandler()

	// Public routes
	r.Post("/api/login", authHandler.Login)

	// Protected routes
	r.Group(func(r chi.Router) {
		r.Use(middleware.AuthMiddleware(cfg.JWTSecret))
		
		// Records endpoints
		r.Post("/api/records", recordsHandler.CreateRecord)
		r.Get("/api/records", recordsHandler.GetRecords)
		r.Delete("/api/records", recordsHandler.DeleteRecord)
		r.Put("/api/records/restore", recordsHandler.RestoreRecord)
		r.Get("/api/records/summary", recordsHandler.GetSummary)
	})

	// Serve static files from web/dist directory in production
	workDir, _ := filepath.Abs(".")
	staticDir := filepath.Join(workDir, "dist")
	fileServer := http.FileServer(http.Dir(staticDir))
	
	r.Get("/*", func(w http.ResponseWriter, r *http.Request) {
		// Check if file exists
		if _, err := http.Dir(staticDir).Open(r.URL.Path); err != nil {
			// If file doesn't exist, serve index.html (for SPA routing)
			http.ServeFile(w, r, filepath.Join(staticDir, "index.html"))
			return
		}
		fileServer.ServeHTTP(w, r)
	})

	// Start server
	addr := ":" + cfg.ServerPort
	log.Printf("Server starting on http://localhost%s", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

