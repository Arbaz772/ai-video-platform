#!/usr/bin/env bash
set -euo pipefail

# Quick automated test for local dev (mock provider)
# Requirements: docker, docker-compose, curl, jq

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Ensure backend env exists
if [ ! -f backend/.env ]; then
  echo "Please create backend/.env from backend/.env.example and set VIDEO_PROVIDER=mock"
  exit 1
fi

echo "1) Ensure helper scripts are executable"
chmod +x scripts/download-sample.sh || true

echo "2) Download sample video (non-fatal)"
./scripts/download-sample.sh || echo "download skipped or failed"

echo "3) Build and start stack"
docker-compose build --pull
docker-compose up -d

# wait for postgres
echo "Waiting for Postgres..."
RETRIES=30
until docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  sleep 1; RETRIES=$((RETRIES-1)); echo -n ".";
done
echo

# create DB if missing and run migrations
if docker-compose exec -T postgres bash -lc "psql -U postgres -d ai_video -c '\q'" >/dev/null 2>&1; then
  echo "ai_video DB exists"
else
  echo "Creating ai_video DB..."
  docker-compose exec -T postgres psql -U postgres -c "CREATE DATABASE ai_video;" || true
fi

if [ -f backend/migrations/001_create_users_and_credits.sql ]; then
  echo "Running migrations..."
  docker cp backend/migrations/001_create_users_and_credits.sql $(docker-compose ps -q postgres):/tmp/mig.sql
  docker-compose exec -T postgres psql -U postgres -d ai_video -f /tmp/mig.sql || echo "Migration may have failed"
fi

API_URL=${PUBLIC_BASE_URL:-http://localhost:4000}

# Signup (or login) test user
EMAIL="test+quick@example.com"
PASS="password123"

echo "Attempting signup for $EMAIL"
SIGNUP=$(curl -s -X POST "$API_URL/signup" -H 'Content-Type: application/json' -d "{"email":"$EMAIL","password":"$PASS"}")
TOKEN=$(echo "$SIGNUP" | jq -r '.token // empty' || true)
if [ -z "$TOKEN" ]; then
  echo "Signup failed or user exists, attempting login..."
  LOGIN=$(curl -s -X POST "$API_URL/login" -H 'Content-Type: application/json' -d "{"email":"$EMAIL","password":"$PASS"}")
  TOKEN=$(echo "$LOGIN" | jq -r '.token // empty' || true)
fi

if [ -z "$TOKEN" ]; then
  echo "Could not obtain token. Backend logs follow for debugging:"
  docker-compose logs backend --tail=200
  exit 1
fi

echo "Obtained token (truncated): ${TOKEN:0:20}..."

# Submit generate job
echo "Submitting generate job"
GEN=$(curl -s -X POST "$API_URL/generate" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"prompt":"Automated quick test","durationMinutes":1}')
JOBID=$(echo "$GEN" | jq -r '.jobId // empty' || true)
if [ -z "$JOBID" ]; then
  echo "Failed to create job: $GEN"; exit 1
fi

echo "Job created: $JOBID"

# Poll the job until completed or timeout
echo "Polling job status (30 attempts)"
for i in $(seq 1 30); do
  sleep 2
  STATUS_JSON=$(curl -s "$API_URL/job/$JOBID")
  echo "$STATUS_JSON" | jq -c .
  STATUS=$(echo "$STATUS_JSON" | jq -r '.status // empty' || true)
  if [ "$STATUS" = "completed" ]; then
    echo "Job completed. Video URL:" $(echo "$STATUS_JSON" | jq -r '.videoUrl')
    exit 0
  fi
done

echo "Timed out waiting for job completion. Check backend logs: docker-compose logs backend --tail=200"
exit 2
