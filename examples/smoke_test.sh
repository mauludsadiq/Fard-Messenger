#!/bin/bash
set -e

BASE="http://127.0.0.1:8080"
ALICE_PK="sha256:8e9f32b2e0ba01533433ad9119cbdb5c70c8497dec380ca4c0f132194c339801"
BOB_PK="sha256:ea33655f21cd3db5fcf9772feb929cb6eed706330661cc13908f4ffdd0ebd5a6"
CONV_ID="${ALICE_PK}:${BOB_PK}"

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; exit 1; }
check() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if $2 else 1)" && pass "$3" || fail "$3"; }

echo ""
echo "=== Fard Messenger smoke test ==="
echo ""

# Start server
rm -f /tmp/fard_messenger_smoke.db
fardrun run --program main.fard --out /tmp/fard_messenger_smoke 2>/dev/null &
SERVER_PID=$!
sleep 2

cleanup() { kill $SERVER_PID 2>/dev/null; rm -f /tmp/fard_messenger_smoke.db; }
trap cleanup EXIT

# Health
R=$(curl -s "$BASE/health")
check "$R" "d['status'] == 'ok'" "health check"

# Text message
R=$(curl -s -X POST "$BASE/message/text" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"text\":\"Hey Bob, want to split the bill?\"}")
check "$R" "d['ok'] == True" "alice sends text"
TEXT_DIGEST=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['content_digest'])")

# Payment request
R=$(curl -s -X POST "$BASE/message/fd_event" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"channel\":\"deposit\",\"payload\":{\"kind\":\"fd_event_v1\",\"event_type\":\"deposit\",\"payload\":{\"beneficiary\":\"alice\",\"usd_cents\":10000,\"deposit_id\":\"DEP-SMOKE-1\",\"oracle_pk\":\"oracle\",\"sig\":\"DEV\"},\"event_hash\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\"}}")
check "$R" "d['ok'] == True" "alice sends fd deposit event"

# Bob replies
R=$(curl -s -X POST "$BASE/message/text" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"bob-seed\",\"to_pk\":\"$ALICE_PK\",\"text\":\"Sure, paying now\"}")
check "$R" "d['ok'] == True" "bob sends text"

# Bob sends read receipt
R=$(curl -s -X POST "$BASE/message/status" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"bob-seed\",\"to_pk\":\"$ALICE_PK\",\"kind\":\"read\",\"target_digest\":\"$TEXT_DIGEST\"}")
check "$R" "d['ok'] == True" "bob sends read receipt"
check "$R" "d['status_kind'] == 'read'" "read receipt kind correct"

# Qasim invite
R=$(curl -s -X POST "$BASE/qasim/invite" -H "Content-Type: application/json" \
  -d "{\"participant_a\":\"$ALICE_PK\",\"participant_b\":\"$BOB_PK\",\"admin_pk\":\"sha256:admin\"}")
check "$R" "d['ok'] == True" "qasim invite"

# Qasim object without invite on different conversation should fail
R=$(curl -s -X POST "$BASE/message/qasim_object" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\",\"channel\":\"fill\",\"payload\":{\"kind\":\"qasim_signed_object_v1\"}}")
check "$R" "d['ok'] == False" "qasim blocked without invite"

# Qasim object after invite
R=$(curl -s -X POST "$BASE/message/qasim_object" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"channel\":\"fill\",\"payload\":{\"kind\":\"qasim_signed_object_v1\",\"object_type\":\"fill\",\"payload_json\":\"{}\",\"issuer_pk_hex\":\"DEV\",\"sig_b64\":\"DEV\",\"object_digest\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\"}}")
check "$R" "d['ok'] == True" "qasim object after invite"

# Conversation retrieval
R=$(curl -s "$BASE/conversation/$CONV_ID")
COUNT=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])")
[ "$COUNT" -ge 4 ] && pass "conversation has $COUNT messages" || fail "conversation message count"

STATUSES=$(echo "$R" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['statuses']))")
[ "$STATUSES" -ge 1 ] && pass "conversation has $STATUSES read receipt(s)" || fail "no statuses in conversation"

# Replay verify
R=$(curl -s "$BASE/replay/verify")
check "$R" "d['ok'] == True" "replay verify ok"
check "$R" "d['match'] == True" "replay head matches stored head"
VERIFIED=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['verified'])")
pass "replay verified $VERIFIED chain entries"

# Chain
R=$(curl -s "$BASE/chain/verify")
CHAIN_COUNT=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])")
[ "$CHAIN_COUNT" -ge 4 ] && pass "chain has $CHAIN_COUNT entries" || fail "chain count"

echo ""
echo "=== all tests passed ==="
echo ""
