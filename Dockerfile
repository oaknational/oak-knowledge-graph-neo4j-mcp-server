# MCP Neo4j Server - Standalone Cloud Run Service
# Python 3.11-slim base per ARCHITECTURE.md requirements

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN groupadd --gid 1000 mcpbot \
    && useradd --uid 1000 --gid mcpbot --shell /bin/bash --create-home mcpbot

# Install system dependencies (minimal for security)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        && rm -rf /var/lib/apt/lists/*

# Install latest MCP Neo4j package from GitHub (supports HTTP transport)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir "git+https://github.com/neo4j-contrib/mcp-neo4j.git#subdirectory=servers/mcp-neo4j-cypher"

# Copy MCP server startup script
COPY mcp_server_start.sh .

# Make startup script executable
RUN chmod +x mcp_server_start.sh

# Change ownership to non-root user
RUN chown -R mcpbot:mcpbot /app

# Switch to non-root user
USER mcpbot

# Expose port 8080 for Cloud Run (MCP server will run on this port)
EXPOSE 8080

# Set environment variable for Cloud Run port
ENV PORT=8080

# Health check using MCP protocol with correct headers
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 \
    CMD curl -X POST http://localhost:8080/api/mcp/ \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":1}' \
        -s --max-time 10 | grep -q "serverInfo" || exit 1

# Run only the MCP server
CMD ["./mcp_server_start.sh"]