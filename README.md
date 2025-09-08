# Neo4j MCP Server on Google Cloud Run

This directory contains the minimal setup for deploying a Neo4j MCP (Model Context Protocol) server on Google Cloud Run.

## Files

- `Dockerfile` - Container configuration for the MCP server
- `mcp_server_start.sh` - Startup script for the MCP server
- `cloudbuild.yaml` - Google Cloud Build configuration for automated deployment
- `.env.example` - Example environment variables

## Deployment

1. Set up environment variables based on `.env.example`
2. Deploy using Cloud Build:
   ```bash
   gcloud builds submit --config=cloudbuild.yaml
   ```

## Environment Variables

- `NEO4J_URI` - Neo4j database connection string
- `NEO4J_USERNAME` - Neo4j username
- `NEO4J_PASSWORD` - Neo4j password
- `PORT` - Server port (managed by Cloud Run, defaults to 8080)

## Usage

Once deployed, the MCP server will be available at:
```
https://neo4j-mcp-server-[PROJECT_HASH].[REGION].run.app/api/mcp/
```

The server accepts MCP protocol requests for Neo4j Cypher query execution.