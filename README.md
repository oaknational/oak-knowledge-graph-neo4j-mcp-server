# Neo4j MCP Server on Google Cloud Run

This repository contains everything needed to deploy a Neo4j MCP (Model Context Protocol) server on Google Cloud Run. The server provides HTTP-based access to Neo4j databases using the MCP protocol.

## Prerequisites

- A Google Cloud Platform account with billing enabled
- A Neo4j database (cloud or self-hosted) with connection details
- Docker installed locally (for testing)
- Git installed

## Step-by-Step Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd oak-knowledge-graph-neo4j-mcp-server
```

### 2. Set Up Environment Variables

Create your environment file:
```bash
cp .env.example .env
```

Edit `.env` with your Neo4j connection details:
```bash
# Example values - replace with your actual Neo4j instance details
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your-password
PORT=8080
```

### 3. Install Google Cloud CLI

**On macOS:**
```bash
# Using Homebrew (recommended)
brew install --cask google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

**On Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**On Windows:**
Download the installer from: https://cloud.google.com/sdk/docs/install

### 4. Configure Google Cloud CLI

Initialize gcloud and authenticate:
```bash
gcloud init
```

Follow the prompts to:
- Log in to your Google account
- Select or create a GCP project
- Choose a default region (recommend: europe-west1 for Europe, us-central1 for US)

Verify your configuration:
```bash
gcloud config get-value project
gcloud config get-value compute/region
```

### 5. Enable Required Google Cloud APIs

```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 6. Configure Deployment Region (Optional)

The default region is set to `europe-west1`. To change it, edit `cloudbuild.yaml`:
```yaml
'--region', 'your-preferred-region',
```

### 7. Test Docker Build (Optional but Recommended)

Build and test the container locally:
```bash
# Build the container
docker build -t neo4j-mcp-test .

# Verify the MCP executable is installed
docker run --rm neo4j-mcp-test which mcp-neo4j-cypher

# Test with your environment (replace with your .env values)
docker run --rm \
  -e NEO4J_URI="your-neo4j-uri" \
  -e NEO4J_USERNAME="your-username" \
  -e NEO4J_PASSWORD="your-password" \
  -p 8080:8080 \
  neo4j-mcp-test
```

### 8. Deploy to Google Cloud Run

Deploy using Cloud Build:
```bash
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_NEO4J_URI="${NEO4J_URI}",_NEO4J_USERNAME="${NEO4J_USERNAME}",_NEO4J_PASSWORD="${NEO4J_PASSWORD}"
```

**Note:** This command reads your environment variables and passes them to Cloud Build. Make sure your `.env` file is properly configured.

### 9. Verify Deployment

After successful deployment, you'll see output like:
```
Service [neo4j-mcp-server] revision [neo4j-mcp-server-00001-xxx] has been deployed and is serving 100 percent of traffic.
Service URL: https://neo4j-mcp-server-xxx-ew.a.run.app
```

Test the deployed service:
```bash
curl -X POST https://your-service-url/api/mcp/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

You should see a response listing available tools:
- `get_neo4j_schema` - Get database schema
- `read_neo4j_cypher` - Execute read queries
- `write_neo4j_cypher` - Execute write queries

## Configuration Files

- **`Dockerfile`** - Container configuration for the MCP server
- **`mcp_server_start.sh`** - Startup script that launches the MCP server
- **`cloudbuild.yaml`** - Google Cloud Build configuration for deployment
- **`.env.example`** - Template for environment variables
- **`.env`** - Your actual environment variables (not committed to git)

## Environment Variables

### Core Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEO4J_URI` | Neo4j connection string | `neo4j+s://xxx.databases.neo4j.io` |
| `NEO4J_USERNAME` | Neo4j username | `neo4j` |
| `NEO4J_PASSWORD` | Neo4j password | `your-secure-password` |
| `PORT` | Server port (managed by Cloud Run) | `8080` |

### HTTP Server Configuration (Automatically Set)

The startup script automatically configures these environment variables for Cloud Run:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `NEO4J_MCP_SERVER_HOST` | Server bind address | `0.0.0.0` |
| `NEO4J_MCP_SERVER_PORT` | Server port | `${PORT}` (from Cloud Run) |
| `NEO4J_MCP_SERVER_PATH` | API endpoint path | `/api/mcp/` |
| `NEO4J_MCP_SERVER_ALLOWED_HOSTS` | Allowed hostnames | Cloud Run hostname + localhost |
| `NEO4J_MCP_SERVER_ALLOW_ORIGINS` | CORS origins | `*` |

## Usage

Once deployed, your MCP server will be available at:
```
https://neo4j-mcp-server-[HASH].[REGION].a.run.app/api/mcp/
```

The server accepts MCP protocol requests for Neo4j Cypher query execution. You can integrate it with Claude Desktop or other MCP-compatible clients.

## Troubleshooting

### Common Issues

**1. "gcloud: command not found"**
```bash
# Reinstall Google Cloud CLI
brew install --cask google-cloud-sdk
# Or follow installation instructions above
```

**2. "Permission denied" errors**
```bash
# Ensure you're authenticated
gcloud auth login
gcloud auth application-default login
```

**3. "API not enabled" errors**
```bash
# Enable required APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com
```

**4. Neo4j connection errors**
- Verify your Neo4j instance is running and accessible
- Check your connection string format
- Ensure credentials are correct
- Test connection from your local machine first

**5. Build failures**
```bash
# Check build logs
gcloud builds list
gcloud builds log [BUILD-ID]
```

**6. "Invalid host header" errors**
This usually means the MCP server isn't configured to accept requests from the Cloud Run hostname. The startup script should automatically configure this, but if you see this error:

- Verify your `mcp_server_start.sh` sets `NEO4J_MCP_SERVER_ALLOWED_HOSTS`
- Check the logs to see what hostname Cloud Run is using
- Ensure the environment variables are being exported correctly

**7. Server won't start or times out**
```bash
# Check recent logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server" --limit=20 --format="value(timestamp,textPayload)" --freshness=1d
```

### Viewing Logs

Check Cloud Run service logs:
```bash
# For recent logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server" --limit=50 --format="value(timestamp,textPayload)" --freshness=1d

# For live logs (if service is running)
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server" --follow
```

### Updating the Service

To update after making changes:
```bash
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_NEO4J_URI="${NEO4J_URI}",_NEO4J_USERNAME="${NEO4J_USERNAME}",_NEO4J_PASSWORD="${NEO4J_PASSWORD}"
```

## MCP Integration

### Available Tools

Once deployed, your server provides these MCP tools:

1. **`get_neo4j_schema`** - Get database schema (nodes, relationships, properties)
2. **`read_neo4j_cypher`** - Execute read-only Cypher queries
3. **`write_neo4j_cypher`** - Execute write Cypher queries (destructive)

### Using with MCP Clients

The server uses Server-Sent Events (SSE) over HTTP, making it compatible with:
- Claude Desktop (via MCP configuration)
- OpenAI with MCP integration
- Custom MCP clients

**Example MCP request:**
```bash
curl -X POST https://your-service-url/api/mcp/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"read_neo4j_cypher",
      "arguments":{"query":"MATCH (n) RETURN count(n) as total_nodes"}
    },
    "id":1
  }'
```

## Security Notes

- The service is deployed with `--allow-unauthenticated` for easy testing
- For production, remove this flag and set up proper authentication
- Consider using Google Secret Manager for sensitive credentials
- The container runs as a non-root user for security
- Host validation prevents unauthorized access attempts

## Cost Optimization

- The service uses minimal resources (512Mi memory, 1 CPU)
- Cloud Run only charges when the service is handling requests
- Automatic scaling down to zero when not in use
- Consider setting `--max-instances` based on your expected load
