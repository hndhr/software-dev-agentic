#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
export KMS_DB_PATH="$DIR/../chroma"
export PYTHONPATH="$DIR/.."
exec python3 -m kms.application.mcp_server
