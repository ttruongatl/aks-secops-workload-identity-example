package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"aks-secops-workload-identity-example/config"
	"aks-secops-workload-identity-example/service"
)

func main() {
	// Initialize Key Vault configuration
	kvConfig, err := config.NewKeyVaultConfig()
	if err != nil {
		log.Fatalf("Failed to initialize Key Vault config: %v", err)
	}

	// Initialize Key Vault service
	kvService, err := service.NewKeyVaultService(kvConfig.VaultName, kvConfig.SecretName)
	if err != nil {
		log.Fatalf("Failed to initialize Key Vault service: %v", err)
	}

	// Get secret value
	ctx := context.Background()
	secretValue, err := kvService.GetSecret(ctx)
	if err != nil {
		log.Fatalf("Failed to get secret: %v", err)
	}

	log.Printf("Successfully retrieved secret from Key Vault: %s", secretValue)

	// Set up HTTP server for health checks
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	// Start server in a goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Error during server shutdown: %v", err)
	}
}
