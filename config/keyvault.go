package config

import (
	"fmt"
	"os"
)

type KeyVaultConfig struct {
	VaultName  string
	SecretName string
}

func NewKeyVaultConfig() (*KeyVaultConfig, error) {
	vaultName := os.Getenv("KEY_VAULT_NAME")
	if vaultName == "" {
		return nil, fmt.Errorf("KEY_VAULT_NAME environment variable is not set")
	}

	secretName := os.Getenv("SECRET_NAME")
	if secretName == "" {
		return nil, fmt.Errorf("SECRET_NAME environment variable is not set")
	}

	return &KeyVaultConfig{
		VaultName:  vaultName,
		SecretName: secretName,
	}, nil
}
