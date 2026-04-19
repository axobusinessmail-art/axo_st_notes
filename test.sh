#!/bin/bash

################################################################################
# GitHub Runner Client - Test Script (Simple Version)
# 
# Purpose: Test communication between client and server without scanning
# Download a chunk, do nothing with it, upload it back
# 
# Usage: ./test.sh
# 
# Hard-coded server: http://axovps.firedns.xyz:8000/
################################################################################

set -e

# ============================================================================
# COLORS & UTILITIES
# ============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# CONFIGURATION (Hard-coded for testing)
# ============================================================================

SERVER_DOMAIN="axovps.firedns.xyz:8000"
BASIC_AUTH="runner:c3ViZG9tYWluX3Rha2VvdmVyX3Rvb2xfYXV0b21hdGlvbg=="  # Base64 of runner:subdomian_takeover_tool_automation

log_info "╔═════════════════════════════════════════════════════════════╗"
log_info "║        GitHub Runner Client - Test (Simple Version)         ║"
log_info "║        Server: http://$SERVER_DOMAIN                    ║"
log_info "╚═════════════════════════════════════════════════════════════╝"

# ============================================================================
# STEP 1: REGISTER RUNNER
# ============================================================================

log_info ""
log_info "STEP 1: Registering Runner..."

response=$(curl -s -w "\n%{http_code}" \
    -X GET \
    "http://$SERVER_DOMAIN/runner-header" \
    -H "Authorization: Basic $BASIC_AUTH")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" != "200" ]; then
    log_error "Registration failed with HTTP $http_code"
    log_error "Response: $body"
    exit 1
fi

RUNNER_HEADER=$(echo "$body" | grep -o '"runner_header":"[^"]*' | cut -d'"' -f4)

if [ -z "$RUNNER_HEADER" ]; then
    log_error "Failed to extract runner_header"
    exit 1
fi

log_success "Runner registered!"
log_success "Runner Header: ${RUNNER_HEADER:0:32}..."

# ============================================================================
# STEP 2: REQUEST CHUNK
# ============================================================================

log_info ""
log_info "STEP 2: Requesting Chunk..."

response=$(curl -s -w "\n%{http_code}" \
    -X GET \
    "http://$SERVER_DOMAIN/subdomain_takeover/chunks?runner_header=$RUNNER_HEADER" \
    -H "Authorization: Basic $BASIC_AUTH")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" != "200" ]; then
    log_error "Chunk request failed with HTTP $http_code"
    log_error "Response: $body"
    exit 1
fi

CHUNK_NAME=$(echo "$body" | grep -o '"chunk_name":"[^"]*' | cut -d'"' -f4)
CHUNK_ID=$(echo "$body" | grep -o '"chunk_id":[0-9]*' | cut -d':' -f2)

if [ -z "$CHUNK_NAME" ]; then
    log_error "Failed to extract chunk_name"
    exit 1
fi

log_success "Chunk received!"
log_success "Chunk Name: $CHUNK_NAME"
log_success "Chunk ID: $CHUNK_ID"

# ============================================================================
# STEP 3: PREPARE TEST RESULT FILE
# ============================================================================

log_info ""
log_info "STEP 3: Preparing test result file..."

# Create a simple test result file
mkdir -p test_results
TEST_RESULT_FILE="test_results/test_result_$(date +%s).txt"

cat > "$TEST_RESULT_FILE" << EOF
Test Result File
================
Generated: $(date)
Chunk Name: $CHUNK_NAME
Chunk ID: $CHUNK_ID
Runner Header: $RUNNER_HEADER
Server: $SERVER_DOMAIN

This is a test upload - no actual scanning performed.
EOF

log_success "Test result file created: $TEST_RESULT_FILE"

# ============================================================================
# STEP 4: UPLOAD RESULT
# ============================================================================

log_info ""
log_info "STEP 4: Uploading result file..."

response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    "http://$SERVER_DOMAIN/subdomain_takeover/result_upload?runner_header=$RUNNER_HEADER&chunk=$CHUNK_NAME" \
    -H "Authorization: Basic $BASIC_AUTH" \
    -F "file=@$TEST_RESULT_FILE")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" != "200" ]; then
    log_error "Upload failed with HTTP $http_code"
    log_error "Response: $body"
    exit 1
fi

log_success "Upload successful!"
log_success "Server response: $body"

# ============================================================================
# COMPLETION
# ============================================================================

log_info ""
log_success "╔═════════════════════════════════════════════════════════════╗"
log_success "║        ✅ TEST COMPLETED SUCCESSFULLY! ✅                   ║"
log_success "║                                                             ║"
log_success "║  Runner: ${RUNNER_HEADER:0:32}...                        ║"
log_success "║  Chunk: $CHUNK_NAME                                   ║"
log_success "║  Upload: SUCCESS                                            ║"
log_success "╚═════════════════════════════════════════════════════════════╝"

exit 0
