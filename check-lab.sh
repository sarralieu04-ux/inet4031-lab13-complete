#!/bin/bash
# check-lab.sh — Docker Lab Verification Script
# Run this from inside your lab12 directory after bringing the stack up.

PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    local hint="$3"
    if [ "$result" = "pass" ]; then
        echo "  [PASS] $desc"
        ((PASS++))
    else
        echo "  [FAIL] $desc"
        [ -n "$hint" ] && echo "         Hint: $hint"
        ((FAIL++))
    fi
}

get_health() {
    local service="$1"
    local cid
    cid=$(docker compose ps -q "$service" 2>/dev/null)
    if [ -z "$cid" ]; then
        echo "not_found"
        return
    fi
    docker inspect --format='{{.State.Health.Status}}' "$cid" 2>/dev/null || echo "no_healthcheck"
}

echo ""
echo "============================================="
echo "  Docker Lab — Check Script"
echo "============================================="
echo ""

# ── 1. Container Health ──────────────────────────
echo "[1] Container Health"
for service in db app; do
    STATUS=$(get_health "$service")
    if [ "$STATUS" = "healthy" ]; then
        check "$service is healthy" "pass"
    else
        check "$service is healthy (current: $STATUS)" "fail" \
            "Run 'docker compose ps' and 'docker compose logs $service' to investigate."
    fi
done

# web has no HEALTHCHECK — just confirm it is running
WEB_CID=$(docker compose ps -q web 2>/dev/null)
if [ -n "$WEB_CID" ]; then
    check "web is running (no healthcheck expected)" "pass"
else
    check "web is running (current: not_found)" "fail" \
        "Run 'docker compose ps' and 'docker compose logs web' to investigate."
fi
echo ""

# ── 2. Apache Reachable on Port 80 ──────────────
echo "[2] Apache Connectivity (port 80)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:80/ 2>/dev/null)
if [[ "$HTTP_CODE" =~ ^(200|301|302|403|404)$ ]]; then
    check "Apache responds on port 80 (HTTP $HTTP_CODE)" "pass"
else
    check "Apache responds on port 80 (got: ${HTTP_CODE:-no response})" "fail" \
        "Check 'docker compose logs web'. Confirm port 80 is mapped in docker-compose.yml."
fi
echo ""

# ── 3. Flask Health Endpoint (via Apache) ────────
echo "[3] Flask Health Endpoint"
HEALTH_RESP=$(curl -s --max-time 5 http://localhost:80/health 2>/dev/null)
if echo "$HEALTH_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
exit(0 if data.get('status') == 'healthy' else 1)
" 2>/dev/null; then
    check "/health returns {status: healthy}" "pass"
else
    check "/health returns {status: healthy}" "fail" \
        "Got: $HEALTH_RESP -- Run 'docker compose logs app' to check Flask startup errors."
fi
echo ""

# ── 4. API Functionality ─────────────────────────
echo "[4] API Functionality"

# GET /api/tickets
TICKETS_RESP=$(curl -s --max-time 5 http://localhost:80/api/tickets 2>/dev/null)
TICKET_COUNT=$(echo "$TICKETS_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(len(data)) if isinstance(data, list) else exit(1)
" 2>/dev/null)
if [ $? -eq 0 ]; then
    check "GET /api/tickets returns a JSON array ($TICKET_COUNT ticket(s))" "pass"
else
    check "GET /api/tickets returns a JSON array" "fail" \
        "Got: $TICKETS_RESP -- Check 'docker compose logs app'."
fi

# POST /api/tickets
POST_RESP=$(curl -s --max-time 5 -X POST http://localhost:80/api/tickets \
    -H "Content-Type: application/json" \
    -d '{"title":"Check Script Test","description":"Created by check-lab.sh","status":"open"}' \
    2>/dev/null)
if echo "$POST_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
exit(0 if 'id' in data else 1)
" 2>/dev/null; then
    NEW_ID=$(echo "$POST_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
    check "POST /api/tickets creates a new ticket (id: $NEW_ID)" "pass"
else
    check "POST /api/tickets creates a new ticket" "fail" \
        "Got: $POST_RESP"
fi
echo ""

# ── 5. Named Volume Exists ───────────────────────
echo "[5] Data Persistence"
VOLUME=$(docker volume ls --format '{{.Name}}' 2>/dev/null | grep 'db-data')
if [ -n "$VOLUME" ]; then
    check "Named volume for MariaDB exists ($VOLUME)" "pass"
else
    check "Named volume for MariaDB exists" "fail" \
        "No volume matching 'db-data' found. Check the 'volumes:' section of your docker-compose.yml."
fi
echo ""

# ── 6. Named Network Exists ──────────────────────
echo "[6] Networking"
NETWORK=$(docker network ls --format '{{.Name}}' 2>/dev/null | grep 'app-network')
if [ -n "$NETWORK" ]; then
    check "Named network 'app-network' exists ($NETWORK)" "pass"
else
    check "Named network 'app-network' exists" "fail" \
        "No network matching 'app-network' found. Check the 'networks:' section of your docker-compose.yml."
fi
echo ""

# ── Summary ──────────────────────────────────────
echo "============================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "============================================="
echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "All checks passed. Take your screenshots and submit."
else
    echo "Some checks failed. Review the hints above and recheck before submitting."
    echo "Your best debugging tools:"
    echo "  docker compose ps"
    echo "  docker compose logs <service>"
    echo "  docker inspect <container_id>"
fi
echo ""
