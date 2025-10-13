# Neo4j MCP Server on Google Cloud Run

Deploy a Neo4j MCP (Model Context Protocol) server to Google Cloud Run. This server provides HTTP-based access to your Neo4j database through the MCP protocol, enabling AI assistants like Claude to query and interact with your graph database.

## What You'll Need

- Google Cloud Platform account with billing enabled
- Neo4j database (cloud or self-hosted) with connection credentials
- Git installed on your machine

## Quick Start

### 1. Clone and Configure

```bash
# Clone this repository
git clone <your-repo-url>
cd oak-knowledge-graph-neo4j-mcp-server

# Create environment file from template
cp .env.example .env
```

Edit `.env` and add your Neo4j credentials:
```bash
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your-secure-password
```

### 2. Install Google Cloud CLI

**macOS:**
```bash
brew install --cask google-cloud-sdk
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Windows:**
Download from: https://cloud.google.com/sdk/docs/install

### 3. Configure Google Cloud

```bash
# Initialize and authenticate
gcloud init

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

When running `gcloud init`, choose or create a project and select a region (e.g., `us-central1` or `europe-west1`).

### 4. Deploy to Cloud Run

```bash
# Load environment variables
source .env

# Deploy
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_NEO4J_URI="${NEO4J_URI}",_NEO4J_USERNAME="${NEO4J_USERNAME}",_NEO4J_PASSWORD="${NEO4J_PASSWORD}"
```

Deployment takes 2-5 minutes. When complete, you'll see:
```
Service [neo4j-mcp-server] has been deployed.
Service URL: https://neo4j-mcp-server-xxxxx-xx.a.run.app
```

### 5. Verify It Works

Test your deployed server:
```bash
curl -X POST https://your-service-url/api/mcp/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

You should see a JSON response listing three available tools:
- `get_neo4j_schema` - Get database schema
- `read_neo4j_cypher` - Execute read queries
- `write_neo4j_cypher` - Execute write queries

## Using Your MCP Server

### With Claude Desktop

Add this configuration to your Claude Desktop MCP settings:

```json
{
  "mcpServers": {
    "neo4j": {
      "url": "https://your-service-url/api/mcp/",
      "transport": "http"
    }
  }
}
```

Restart Claude Desktop. You can now ask Claude to query your Neo4j database:
- "What's the schema of my Neo4j database?"
- "Run a query to find all nodes"
- "Create a new node with these properties"

### With Other MCP Clients

This server uses **Streamable HTTP transport** (MCP spec 2025-03-26) and works with any MCP-compatible client. Send JSON-RPC requests to `/api/mcp/` endpoint.

Example query request:
```bash
curl -X POST https://your-service-url/api/mcp/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"read_neo4j_cypher",
      "arguments":{"query":"MATCH (n) RETURN count(n) as total"}
    },
    "id":1
  }'
```

## Configuration

### Environment Variables

Required variables (set in `.env`):

| Variable | Description | Example |
|----------|-------------|---------|
| `NEO4J_URI` | Neo4j connection string | `neo4j+s://abc.databases.neo4j.io` |
| `NEO4J_USERNAME` | Neo4j username | `neo4j` |
| `NEO4J_PASSWORD` | Neo4j password | `your-password` |

Optional variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ALLOWED_HOSTS` | Comma-separated list of allowed hostnames | Auto-configured |
| `ALLOW_ORIGINS` | CORS allowed origins (browser requests only) | `*` (all origins) |

### Deployment Settings

Edit `cloudbuild.yaml` to customize:

```yaml
substitutions:
  _REGION: "europe-west1"  # Change deployment region
  _SERVICE: "neo4j-mcp-server"  # Change service name
  _RUNTIME_SA: "your-service-account@project.iam.gserviceaccount.com"
```

Resource limits (in `cloudbuild.yaml`):
- Memory: 512Mi (adjustable with `--memory` flag)
- CPU: 1 (adjustable with `--cpu` flag)
- Max instances: 10 (adjustable with `--max-instances` flag)

## Maintenance

### Update After Code Changes

```bash
source .env
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_NEO4J_URI="${NEO4J_URI}",_NEO4J_USERNAME="${NEO4J_USERNAME}",_NEO4J_PASSWORD="${NEO4J_PASSWORD}"
```

### View Logs

```bash
# Recent logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server" \
  --limit=50 --freshness=1d

# Live streaming logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server" \
  --follow
```

### Check Build History

```bash
gcloud builds list --limit=10
gcloud builds log [BUILD-ID]
```

## Troubleshooting

**Authentication errors:**
```bash
gcloud auth login
gcloud auth application-default login
```

**API not enabled:**
```bash
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com
```

**Neo4j connection fails:**
- Verify your Neo4j instance is running and accessible
- Test credentials using Neo4j Browser or another client
- Check that your connection string uses the correct protocol (`neo4j+s://` for encrypted)

**Build fails:**
```bash
# Check logs for the failed build
gcloud builds list
gcloud builds log [BUILD-ID]
```

**Deployment fails:**
- Ensure all required substitution variables are provided
- Verify your service account has necessary permissions
- Check that your project has billing enabled

## Security Considerations

**Current security posture:**
- ✅ HTTPS encryption for all traffic (enforced by Cloud Run)
- ✅ Container runs as non-root user
- ⚠️ Service is publicly accessible (`--allow-unauthenticated`)

**The `--allow-unauthenticated` flag means:**
- Anyone with the URL can send requests to your MCP server
- No authentication is required to access Neo4j through the MCP interface
- Suitable for development, testing, or internal tools
- **Not recommended for production with sensitive data**

**For production deployments:**
1. Remove `--allow-unauthenticated` from `cloudbuild.yaml`
2. Use Google Cloud IAM for authentication
3. Store credentials in Google Secret Manager instead of environment variables
4. Restrict CORS origins in `ALLOW_ORIGINS` if serving browser clients
5. Regularly rotate Neo4j credentials
6. Set up monitoring and alerting for unusual access patterns

## Cost Information

**Cloud Run pricing:**
- Only charged when handling requests (pay-per-use)
- Automatically scales to zero when not in use
- Uses minimal resources (512Mi memory, 1 CPU)

**Cloud Build pricing:**
- Uses `E2_HIGHCPU_8` machine for faster builds
- To reduce costs, change `machineType` in `cloudbuild.yaml` to `E2_HIGHCPU_4` or default

**Estimated costs for light usage:**
- ~$1-5/month for occasional requests
- Refer to Google Cloud pricing calculator for your specific usage

## What's Included

- **`Dockerfile`** - Defines the container with MCP Neo4j server (v0.4.1)
- **`mcp_server_start.sh`** - Startup script that configures and launches the server
- **`cloudbuild.yaml`** - Cloud Build configuration for automated deployment
- **`.env.example`** - Template for environment variables

## Resources

- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [Neo4j MCP Server GitHub](https://github.com/neo4j-contrib/mcp-neo4j)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Neo4j Documentation](https://neo4j.com/docs/)
