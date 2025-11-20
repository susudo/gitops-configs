# Create update-keyvault-config.sh
cat > update-keyvault-config.sh << 'EOF'
#!/bin/bash

echo "🔐 Updating Key Vault configuration in GitOps repository..."

# Get values from Terraform
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Get Key Vault Secrets Provider managed identity client ID (CORRECT METHOD)
KV_SECRETS_PROVIDER_CLIENT_ID=$(az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv)

echo "📋 Configuration values:"
echo "  Key Vault Name: $KEY_VAULT_NAME"
echo "  Tenant ID: $TENANT_ID"  
echo "  Key Vault Secrets Provider Client ID: $KV_SECRETS_PROVIDER_CLIENT_ID"

# Path to your GitOps repository (update this path)
GITOPS_REPO_PATH="/path/to/your/gitops-configs"  # ← Update this path

if [ ! -d "$GITOPS_REPO_PATH" ]; then
  echo "❌ GitOps repository not found at: $GITOPS_REPO_PATH"
  echo "   Please update GITOPS_REPO_PATH in this script"
  exit 1
fi

# Update the key-vault-secrets.yaml file
KEY_VAULT_FILE="$GITOPS_REPO_PATH/3tire-configs/key-vault-secrets.yaml"

if [ -f "$KEY_VAULT_FILE" ]; then
  echo "🔄 Updating $KEY_VAULT_FILE..."
  
  # Create backup
  cp "$KEY_VAULT_FILE" "$KEY_VAULT_FILE.backup"
  
  # Replace placeholders with actual values
  sed -i "s/REPLACE_WITH_KUBELET_CLIENT_ID/$KV_SECRETS_PROVIDER_CLIENT_ID/g" "$KEY_VAULT_FILE"
  sed -i "s/REPLACE_WITH_KEY_VAULT_NAME/$KEY_VAULT_NAME/g" "$KEY_VAULT_FILE"
  sed -i "s/REPLACE_WITH_AZURE_TENANT_ID/$TENANT_ID/g" "$KEY_VAULT_FILE"
  
  echo "✅ Key Vault configuration updated successfully!"
  echo "🚀 Next steps:"
  echo "   1. Review the changes: git diff"
  echo "   2. Commit and push: git add . && git commit -m 'Update Key Vault configuration' && git push"
  echo "   3. ArgoCD will automatically sync the changes"
else
  echo "❌ Key Vault secrets file not found: $KEY_VAULT_FILE"
  echo "   Make sure your GitOps repository is properly set up"
fi
EOF

chmod +x update-keyvault-config.sh