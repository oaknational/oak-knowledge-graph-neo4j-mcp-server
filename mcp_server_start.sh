#!/bin/bash
# MCP Neo4j Server Startup Script - Standalone Service
# Runs only the MCP Neo4j server for isolated testing

set -e

echo "Starting standalone MCP Neo4j server..."
echo "PORT: ${PORT}"

# Validate required environment variables
if [ -z "$NEO4J_URI" ] || [ -z "$NEO4J_USERNAME" ] || [ -z "$NEO4J_PASSWORD" ]; then
    echo "❌ Missing required environment variables: NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD"
    exit 1
fi

# Configure HTTP server settings via environment variables
export NEO4J_MCP_SERVER_HOST="0.0.0.0"
export NEO4J_MCP_SERVER_PORT="${PORT}"
export NEO4J_MCP_SERVER_PATH="/api/mcp/"
export NEO4J_MCP_SERVER_ALLOWED_HOSTS="${ALLOWED_HOSTS:-localhost,127.0.0.1}"

# CORS configuration - NOTE: Only restricts browser requests, not direct API calls
# Defaults to "*" (allows all origins). Set ALLOW_ORIGINS to restrict browser access.
# Example: ALLOW_ORIGINS="https://my-frontend.com,https://app.example.com"
# WARNING: This does NOT prevent curl, Postman, or server-to-server requests.
export NEO4J_MCP_SERVER_ALLOW_ORIGINS="${ALLOW_ORIGINS:-*}"

# Start MCP server on Cloud Run port with HTTP transport
echo "Starting mcp-neo4j-cypher server in HTTP mode on port ${PORT}..."
echo "Allowed hosts: ${NEO4J_MCP_SERVER_ALLOWED_HOSTS}"

# Use HTTP transport (Streamable HTTP) - recommended as of MCP spec 2025-03-26
# SSE transport was deprecated in favor of Streamable HTTP
exec mcp-neo4j-cypher \
    --transport http \
    --db-url "${NEO4J_URI}" \
    --username "${NEO4J_USERNAME}" \
    --password "${NEO4J_PASSWORD}"
