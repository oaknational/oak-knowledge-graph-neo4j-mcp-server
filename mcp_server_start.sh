#!/bin/bash
# MCP Neo4j Server Startup Script - Standalone Service
# Runs only the MCP Neo4j server for isolated testing

set -e

echo "Starting standalone MCP Neo4j server..."
echo "NEO4J_URI: ${NEO4J_URI}"
echo "NEO4J_USERNAME: ${NEO4J_USERNAME}"
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
export NEO4J_MCP_SERVER_ALLOWED_HOSTS="neo4j-mcp-server-6336353060.europe-west1.run.app,localhost,127.0.0.1"
export NEO4J_MCP_SERVER_ALLOW_ORIGINS="*"

# Start MCP server on Cloud Run port with SSE transport
echo "Starting mcp-neo4j-cypher server in SSE mode on port ${PORT}..."
echo "Allowed hosts: ${NEO4J_MCP_SERVER_ALLOWED_HOSTS}"

# Use SSE transport mode for AI SDK SSEClientTransport compatibility
exec mcp-neo4j-cypher \
    --transport sse \
    --db-url "${NEO4J_URI}" \
    --username "${NEO4J_USERNAME}" \
    --password "${NEO4J_PASSWORD}"