# GitHub Runner Client Suite - Complete Documentation

## Overview

This suite provides a complete distributed subdomain takeover scanning solution using GitHub Actions and the GitHub Runner Controller server.

**Components:**
- `main.sh` - Production scanner client with full pipeline
- `test.sh` - Simple test client for validating server connection
- `adder.sh` - Utility for adding prefixes to scan results
- `.github/workflows/production.yml` - Production workflow with 20 parallel jobs
- `.github/workflows/test-trigger.yml` - Simple push-based test workflow

---

## Quick Start

### 1. Clone Repository
```bash
cd axo_st_notes
git clone <your-repo>
```

### 2. Setup GitHub Actions Secrets
Go to: **Settings → Secrets and variables → Actions**

Add these secrets:
- `SLACK_WEBHOOK` - Your Slack webhook URL
- `SERVER_DOMAIN` - Scanner server address (e.g., `server.com:8001`)
- `BASIC_AUTH` - Base64 encoded credentials

### 3. Test Connection
```bash
# Make test script executable
chmod +x test.sh

# Run test
./test.sh
```

### 4. Deploy Production
```bash
# Make scripts executable
chmod +x main.sh adder.sh

# Push to trigger GitHub Actions
git add .
git commit -m "Deploy GitHub Runner client"
git push
```

---

## Detailed Setup

### GitHub Actions Secrets Configuration

#### SLACK_WEBHOOK
1. Go to your Slack workspace
2. Create an Incoming Webhook: https://api.slack.com/apps
3. Copy the webhook URL
4. Add as GitHub secret: `SLACK_WEBHOOK`

**Example:** `https://hooks.slack.com/services/TXXX/BXXX/XXXX`

#### SERVER_DOMAIN
Set your GitHub Runner Controller server address

**Examples:**
- `localhost:8001` (local development)
- `example.com:8001` (production)
- `192.168.1.100:8001` (private network)
- `axovps.firedns.xyz:8000` (public server)

#### BASIC_AUTH
Encode your credentials in Base64

**Default credentials:**
```
Username: runner
Password: subdomian_takeover_tool_automation
```

**Encode:**
```bash
echo -n "runner:subdomian_takeover_tool_automation" | base64
# Output: cnVubmVyOnN1YmRvbWlhbl90YWtlb3Zlcl90b29sX2F1dG9tYXRpb24=
```

---

## Script Documentation

### main.sh - Production Scanner

**Purpose:** Full distributed scanning pipeline

**Stages:**
1. **Setup** - Install nuclei and subdominator
2. **Initialization** - Validate environment variables
3. **Validation** - Check tool installation
4. **Execution** - Register with server and get chunk
5. **Scanning** - Run nuclei and subdominator
6. **Merging** - Combine and deduplicate results
7. **Naming** - Add random hash to prevent duplicates
8. **Upload** - Send results to server

**Usage:**
```bash
./main.sh
```

**Environment Variables Required:**
- `SLACK_WEBHOOK` - Slack webhook for notifications
- `SERVER_DOMAIN` - Server address
- `BASIC_AUTH` - Base64 credentials

**Output:**
- `targets/` - Downloaded chunk files
- `results/` - Scan results from nuclei and subdominator
- `results/raw_merged_result_*.txt` - Final deduplicated results

### test.sh - Simple Test Client

**Purpose:** Quick validation of server connection

**What it does:**
1. Registers with server
2. Requests a chunk
3. Creates a test result file
4. Uploads result to server

**Usage:**
```bash
chmod +x test.sh
./test.sh
```

**Hard-coded Server:** `axovps.firedns.xyz:8000`

**Output:**
```
✅ TEST COMPLETED SUCCESSFULLY! ✅

Runner: abc123...
Chunk: chunk_1.txt
Upload: SUCCESS
```

### adder.sh - Result Prefix Utility

**Purpose:** Add prefixes to scan output for identification

**Usage:**
```bash
bash adder.sh -add "[nuclei-scan]" -i results/nuclei_output.txt
bash adder.sh -add "[subdominator-scan]" -i results/subdominator_output.txt
```

**Example:**
```
Input:  example.com
Output: [nuclei-scan] example.com

Input:  subdomain.example.com
Output: [subdominator-scan] subdomain.example.com
```

---

## GitHub Actions Workflows

### test-trigger.yml - Simple Push-Based Workflow

**Trigger:** Push to `trigger/` directory

**What it does:**
1. Listens for pushes to repository
2. Checks if `trigger/` directory was modified
3. Sends Discord/Slack notification on completion

**Setup:**
```bash
# Create trigger directory
mkdir trigger
echo "test" > trigger/README.md

# Commit and push
git add trigger/
git commit -m "Trigger workflow test"
git push
```

**Workflow file:**
```
.github/workflows/test-trigger.yml
```

### production.yml - Production Scanner with 20 Parallel Jobs

**Trigger:** 
- Push to main/master/production branch
- Manual trigger from Actions tab
- Scheduled every 4 hours

**Features:**
- 20 parallel scanner jobs using matrix strategy
- Each job runs independently
- Shared environment variables from GitHub secrets
- Automatic artifact collection
- Slack/Discord notifications
- Comprehensive error handling

**Parallel Jobs (Matrix):**
```yaml
strategy:
  matrix:
    job_id: [1, 2, 3, ..., 20]
```

Each job executes `main.sh` with its own runner environment.

**Workflow Stages:**

1. **Metadata** - Generates workflow information
2. **Validate Environment** - Checks secrets are configured
3. **Scan (20x)** - Parallel scanning jobs
4. **Summary** - Collects results and sends notifications

**Artifacts:**
- Collected as `scan-results-job-{job_id}`
- Available for 30 days
- Downloaded after all jobs complete

**Usage:**
```yaml
# Manual trigger
- Go to Actions tab
- Select "Production - Subdomain Takeover Scanner"
- Click "Run workflow"
- Choose branch and click green button

# Automatic on push
- Commit and push to main/master/production
- Workflow runs automatically
```

---

## Execution Flow

### Single Job Flow (main.sh)

```
┌─────────────────────────────────────────┐
│ 1. SETUP                                │
│ - apt update/upgrade                    │
│ - Install unzip, curl, wget             │
│ - Install nuclei (latest)               │
│ - Install subdominator (latest)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 2. INITIALIZATION                       │
│ - Validate SLACK_WEBHOOK                │
│ - Validate SERVER_DOMAIN                │
│ - Validate BASIC_AUTH                   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 3. VALIDATION                           │
│ - Check nuclei installed                │
│ - Check subdominator installed          │
│ - Retry on failure                      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 4. EXECUTION - Register & Get Chunk    │
│ - POST /runner-header → RUNNER_HEADER   │
│ - GET /chunks → CHUNK_NAME              │
│ - Download chunk to targets/            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 5. SCANNING                             │
│ - Run subdominator -l targets/...       │
│ - Run nuclei -l targets/...             │
│ - Add prefixes to results               │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 6. MERGING                              │
│ - Combine nuclei + subdominator output  │
│ - Sort and deduplicate                  │
│ - Save to raw_merged_result.txt         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 7. NAMING                               │
│ - Generate random hash                  │
│ - Rename to raw_merged_result_{hash}.txt│
│ - Store in $UPLOAD_FILE                 │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 8. UPLOAD                               │
│ - POST /result_upload with file         │
│ - Retry up to 10 times                  │
│ - Send Slack notification on success    │
└─────────────────────────────────────────┘
```

### Production Workflow Flow (20 Parallel Jobs)

```
┌──────────────────────────────────────────────────────────┐
│ TRIGGER: Push to main/master/production or manual run    │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ 1. METADATA JOB (single)                                 │
│ - Generate workflow metadata                            │
│ - Display workflow information                          │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ 2. VALIDATE ENVIRONMENT JOB (single)                     │
│ - Check SLACK_WEBHOOK set                              │
│ - Check SERVER_DOMAIN set                              │
│ - Check BASIC_AUTH set                                 │
│ - Test server connectivity                             │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ 3. SCAN JOBS (20 parallel)                              │
│ ┌────────┬────────┬────────┬─────────┐                  │
│ │ Job 1  │ Job 2  │ Job 3  │ ...     │                  │
│ │        │        │        │ Job 20  │                  │
│ │ main.sh│ main.sh│ main.sh│ main.sh │                  │
│ └────────┴────────┴────────┴─────────┘                  │
│   All run simultaneously with max 20 parallel            │
│   Each uploads its own results with unique filename     │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ 4. SUMMARY JOB (single)                                 │
│ - Collect all artifacts                                │
│ - Generate execution report                            │
│ - Send completion notification                         │
└──────────────────────────────────────────────────────────┘
```

---

## Error Handling & Retries

### Registration Retry Logic
- Max attempts: 10
- Sleep between retries: 2 seconds
- Fails if all 10 attempts exhausted

### Chunk Request Retry Logic
- Max attempts: 10
- Sleep between retries: 2 seconds
- Special handling for HTTP 204 (no chunks)

### Upload Retry Logic
- Max attempts: 10
- Sleep between retries: 2 seconds
- Preserves file with unique hash before retry

### Tool Installation Retry
- Nuclei: Retry installation up to 2 times
- Subdominator: Retry installation up to 2 times
- Sends Slack notification on final failure

---

## Slack Notifications

### Success Notification
```
✅ GitHub Runner Client execution completed successfully
Repository: ...
Server response: ...
```

### Error Notifications
```
❌ Runner registration failed
❌ Chunk request failed
❌ Result upload failed
❌ Nuclei installation failed
❌ Subdominator installation failed
```

---

## File Structure

```
axo_st_notes/
├── main.sh                    # Production scanner
├── test.sh                    # Simple test client
├── adder.sh                   # Result prefix utility
├── .env.example               # Environment template
├── README.md                  # This file
└── .github/
    └── workflows/
        ├── test-trigger.yml   # Push-based test workflow
        └── production.yml     # Production 20-parallel workflow
```

---

## Running Locally (Development)

### Prerequisites
```bash
# Install required tools
sudo apt-get update
sudo apt-get install -y curl wget unzip

# Install nuclei
curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest \
  | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | wget -qi -
unzip nuclei_*_linux_amd64.zip
sudo mv nuclei /usr/local/bin

# Install subdominator
wget -q https://github.com/Stratus-Security/Subdominator/releases/download/v1.72/Subdominator
sudo mv Subdominator /usr/local/bin/subdominator
sudo chmod +x /usr/local/bin/subdominator
```

### Run Test Script
```bash
chmod +x test.sh
./test.sh
```

### Run Production Script
```bash
export SLACK_WEBHOOK="https://hooks.slack.com/..."
export SERVER_DOMAIN="server.com:8001"
export BASIC_AUTH="cnVubmVy..."

chmod +x main.sh adder.sh
./main.sh
```

---

## Troubleshooting

### Connection Refused
```
Error: Failed to connect to server
Solution: Check SERVER_DOMAIN is correct and server is running
```

### Authentication Failed
```
Error: Invalid credentials (HTTP 401)
Solution: Verify BASIC_AUTH is properly base64 encoded
```

### No Chunks Available
```
Error: No chunks available (HTTP 204)
Solution: Add more chunks to server or wait for chunk allocation
```

### Tool Installation Failed
```
Error: Nuclei installation failed
Solution: Check internet connectivity, verify GitHub API not rate-limited
```

### Artifacts Not Collected
```
Issue: Scan results not uploaded
Solution: Check results/ directory has files, verify upload succeeded
```

---

## Performance Notes

- **Parallel Jobs**: 20 jobs run simultaneously
- **Job Timeout**: 30 minutes per job
- **Artifact Retention**: 30 days
- **Matrix Strategy**: `max-parallel: 20` with `fail-fast: false`

---

## Security Considerations

1. **Never commit secrets** - Use GitHub Actions secrets only
2. **Base64 is encoding, not encryption** - Don't expose base64 credentials
3. **Webhook security** - Keep Slack/Discord webhooks private
4. **Access control** - Limit who can trigger workflows
5. **Audit logs** - GitHub Actions logs all executions

---

## Support & Debugging

### Check GitHub Actions Logs
1. Go to your repository
2. Click "Actions" tab
3. Select the workflow run
4. Click the job to view logs

### Check Slack Notifications
- All errors send notifications
- Check your configured Slack channel
- Look for error type and details

### Enable Debug Logging
Add to workflow:
```yaml
- name: Enable debug logging
  run: |
    set -x
    # Commands will be printed as executed
```

---

## Next Steps

1. ✅ Create GitHub repository
2. ✅ Configure GitHub Actions secrets
3. ✅ Push code to repository
4. ✅ Create `trigger/` directory (optional)
5. ✅ Monitor workflow execution
6. ✅ Check results in artifacts
7. ✅ Adjust settings based on production needs

---

**Last Updated:** April 2026
**Version:** 2.0.0
**Status:** Production Ready
