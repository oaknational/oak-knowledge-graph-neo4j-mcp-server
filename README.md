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
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":1}'
```

## Configuration Files

- **`Dockerfile`** - Container configuration for the MCP server
- **`mcp_server_start.sh`** - Startup script that launches the MCP server
- **`cloudbuild.yaml`** - Google Cloud Build configuration for deployment
- **`.env.example`** - Template for environment variables
- **`.env`** - Your actual environment variables (not committed to git)

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEO4J_URI` | Neo4j connection string | `neo4j+s://xxx.databases.neo4j.io` |
| `NEO4J_USERNAME` | Neo4j username | `neo4j` |
| `NEO4J_PASSWORD` | Neo4j password | `your-secure-password` |
| `PORT` | Server port (managed by Cloud Run) | `8080` |

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

### Viewing Logs

Check Cloud Run service logs:
```bash
gcloud logs tail --follow \
  --filter="resource.type=cloud_run_revision AND resource.labels.service_name=neo4j-mcp-server"
```

### Updating the Service

To update after making changes:
```bash
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_NEO4J_URI="${NEO4J_URI}",_NEO4J_USERNAME="${NEO4J_USERNAME}",_NEO4J_PASSWORD="${NEO4J_PASSWORD}"
```

## Security Notes

- The service is deployed with `--allow-unauthenticated` for easy testing
- For production, remove this flag and set up proper authentication
- Consider using Google Secret Manager for sensitive credentials
- The container runs as a non-root user for security

## Cost Optimization

- The service uses minimal resources (512Mi memory, 1 CPU)
- Cloud Run only charges when the service is handling requests
- Automatic scaling down to zero when not in use
- Consider setting `--max-instances` based on your expected load
