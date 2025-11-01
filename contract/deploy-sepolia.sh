#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env.sepolia"

if [[ -f "$ENV_FILE" ]]; then
  echo "Loading environment variables from $ENV_FILE..."
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Environment file $ENV_FILE not found!"
  exit 1
fi

cleanup_env() {
  echo "Cleaning up environment variables..."
  unset STARKNET_RPC_URL || true
  unset DOJO_ACCOUNT_ADDRESS || true
  unset DOJO_PRIVATE_KEY || true
  echo "Environment variables cleared."
}
trap cleanup_env EXIT

# Ensure required envs
: "${STARKNET_RPC_URL:?missing STARKNET_RPC_URL}"
: "${DOJO_ACCOUNT_ADDRESS:?missing DOJO_ACCOUNT_ADDRESS}"
: "${DOJO_PRIVATE_KEY:?missing DOJO_PRIVATE_KEY}"

# Build
echo "Building (sepolia profile)..."
sozo --profile sepolia build

# Deploy/migrate
echo "Migrating to Sepolia..."
sozo --profile sepolia migrate \
  --account-address "$DOJO_ACCOUNT_ADDRESS" \
  --private-key "$DOJO_PRIVATE_KEY" \
  --fee strk

echo "Deployment completed successfully."
