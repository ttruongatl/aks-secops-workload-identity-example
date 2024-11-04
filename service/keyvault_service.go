package service

import (
	"context"
	"fmt"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
)

type KeyVaultService struct {
	client     *azsecrets.Client
	secretName string
}

func NewKeyVaultService(vaultName, secretName string) (*KeyVaultService, error) {
	vaultURL := fmt.Sprintf("https://%s.vault.azure.net/", vaultName)

	// Create a credential using Workload Identity
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create credential: %v", err)
	}

	// Create a client
	client, err := azsecrets.NewClient(vaultURL, cred, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create client: %v", err)
	}

	return &KeyVaultService{
		client:     client,
		secretName: secretName,
	}, nil
}

func (s *KeyVaultService) GetSecret(ctx context.Context) (string, error) {
	resp, err := s.client.GetSecret(ctx, s.secretName, "", nil)
	if err != nil {
		return "", fmt.Errorf("failed to get secret: %v", err)
	}

	return *resp.Value, nil
}
