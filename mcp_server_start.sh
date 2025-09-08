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

# Start MCP server on Cloud Run port with HTTP transport
echo "Starting mcp-neo4j-cypher server in HTTP mode on port ${PORT}..."

# Use HTTP transport mode per Neo4j MCP documentation
exec mcp-neo4j-cypher \
    --transport http \
    --server-host "0.0.0.0" \
    --server-port "${PORT}" \
    --server-path "/api/mcp/" \
    --db-url "${NEO4J_URI}" \
    --username "${NEO4J_USERNAME}" \
    --password "${NEO4J_PASSWORD}"