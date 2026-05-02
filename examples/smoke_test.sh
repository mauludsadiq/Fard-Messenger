#!/bin/bash
set -e

BASE="http://127.0.0.1:8081"
ALICE_PK="sha256:8e9f32b2e0ba01533433ad9119cbdb5c70c8497dec380ca4c0f132194c339801"
BOB_PK="sha256:ea33655f21cd3db5fcf9772feb929cb6eed706330661cc13908f4ffdd0ebd5a6"
CONV_ID="${ALICE_PK}:${BOB_PK}"

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; exit 1; }
check() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if $2 else 1)" && pass "$3" || fail "$3"; }

echo ""
echo "=== Fard Messenger smoke test v0.2.0 ==="
echo ""

rm -f /tmp/fard_messenger_smoke.db
rm -f /tmp/fard_messenger_smoke/result.json
fardrun run --program main.fard --out /tmp/fard_messenger_smoke 2>/dev/null &
SERVER_PID=$!
sleep 2

cleanup() { kill $SERVER_PID 2>/dev/null; rm -f /tmp/fard_messenger_smoke.db; }
trap cleanup EXIT

# Health
R=$(curl -s "$BASE/health")
check "$R" "d['status'] == 'ok'" "health check"

# Alice sends text
R=$(curl -s -X POST "$BASE/message/text" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"text\":\"Hey Bob, want to split the bill?\"}")
check "$R" "d['ok'] == True" "alice sends text"
TEXT_DIGEST=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['content_digest'])")

# Alice sends FD event
R=$(curl -s -X POST "$BASE/message/fd_event" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"channel\":\"deposit\",\"payload\":{\"kind\":\"fd_event_v1\",\"event_type\":\"deposit\",\"payload\":{\"beneficiary\":\"alice\",\"usd_cents\":10000,\"deposit_id\":\"DEP-SMOKE-1\",\"oracle_pk\":\"oracle\",\"sig\":\"DEV\"},\"event_hash\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\"}}")
check "$R" "d['ok'] == True" "alice sends fd deposit event"
FD_DIGEST=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['content_digest'])")

# Bob sends delivered, received, read lifecycle
R=$(curl -s -X POST "$BASE/message/status" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"bob-seed\",\"to_pk\":\"$ALICE_PK\",\"kind\":\"delivered\",\"target_digest\":\"$TEXT_DIGEST\"}")
check "$R" "d['ok'] == True" "bob sends delivered"
check "$R" "d['status_kind'] == 'delivered'" "delivered kind correct"

R=$(curl -s -X POST "$BASE/message/status" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"bob-seed\",\"to_pk\":\"$ALICE_PK\",\"kind\":\"received\",\"target_digest\":\"$TEXT_DIGEST\"}")
check "$R" "d['ok'] == True" "bob sends received"

R=$(curl -s -X POST "$BASE/message/status" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"bob-seed\",\"to_pk\":\"$ALICE_PK\",\"kind\":\"read\",\"target_digest\":\"$TEXT_DIGEST\"}")
check "$R" "d['ok'] == True" "bob sends read"
check "$R" "d['status_kind'] == 'read'" "read kind correct"

# Qasim invite and object
R=$(curl -s -X POST "$BASE/qasim/invite" -H "Content-Type: application/json" \
  -d "{\"participant_a\":\"$ALICE_PK\",\"participant_b\":\"$BOB_PK\",\"admin_pk\":\"sha256:admin\"}")
check "$R" "d['ok'] == True" "qasim invite"

R=$(curl -s -X POST "$BASE/message/qasim_object" -H "Content-Type: application/json" \
  -d "{\"from_seed\":\"alice-seed\",\"to_pk\":\"$BOB_PK\",\"channel\":\"fill\",\"payload\":{\"kind\":\"qasim_signed_object_v1\",\"object_type\":\"fill\",\"payload_json\":\"{}\",\"issuer_pk_hex\":\"DEV\",\"sig_b64\":\"DEV\",\"object_digest\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\"}}")
check "$R" "d['ok'] == True" "qasim object after invite"
QASIM_DIGEST=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['content_digest'])")

# Retrieve message by digest
R=$(curl -s "$BASE/message/$TEXT_DIGEST")
check "$R" "d['ok'] == True" "retrieve message by digest"
check "$R" "d['message']['channel'] == 'text'" "message channel correct"

R=$(curl -s "$BASE/message/$FD_DIGEST")
check "$R" "d['ok'] == True" "retrieve fd message by digest"
check "$R" "d['message']['channel'] == 'finance_fd'" "fd message channel correct"

# Read thread with per-message statuses
R=$(curl -s "$BASE/conversation/$CONV_ID")
check "$R" "d['count'] >= 3" "conversation has messages"
STATUS_COUNT=$(echo "$R" | TEXT_DIGEST="$TEXT_DIGEST" python3 -c "
import sys,json,os
data=json.load(sys.stdin)
tgt_digest=os.environ['TEXT_DIGEST']
msgs=data['messages']
tgt=[m for m in msgs if m['content_digest']==tgt_digest]
print(len(tgt[0]['statuses']) if tgt else 0)
")
[ "$STATUS_COUNT" -ge 3 ] && pass "target message has $STATUS_COUNT statuses (delivered/received/read)" || fail "per-message statuses"

# Thread digest
R=$(curl -s "$BASE/conversation/$CONV_ID/digest")
check "$R" "d['ok'] == True" "thread digest ok"
check "$R" "d['message_count'] >= 3" "thread digest message count"
check "$R" "d['history_digest'] != ''" "thread digest has history_digest"
pass "thread head: $(echo $R | python3 -c "import sys,json; print(json.load(sys.stdin)['head'][:16])...")..."

# Replay verify
R=$(curl -s "$BASE/replay/verify")
check "$R" "d['ok'] == True" "replay verify ok"
check "$R" "d['match'] == True" "replay head matches"
VERIFIED=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['verified'])")
pass "replay verified $VERIFIED chain entries"

# Chain
R=$(curl -s "$BASE/chain/verify")
CHAIN_COUNT=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])")
[ "$CHAIN_COUNT" -ge 5 ] && pass "chain has $CHAIN_COUNT entries" || fail "chain count"

echo ""
echo "=== all tests passed ==="
echo ""
