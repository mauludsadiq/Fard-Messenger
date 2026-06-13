# Fard Messenger

Fard Messenger is a deterministic messaging application built entirely in FARD.

It supports normal conversations — text, payments, commands, read receipts, offline delivery, and inbox state — while every message is cryptographically verifiable, replayable, and permanently auditable.

Two people — Malik and Samiyah — can text like any modern app. Under the surface, every message produces a chain-linked receipt.

---

## Core Guarantee

Same messages -> same state -> same SHA-256 digest.

Every message commits to content, sender, recipient, envelope, execution result, and global chain state.

There is no hidden state, no mutation outside the chain, and no ambiguity.

---

## Built in FARD

Fard Messenger is written entirely in FARD.

FARD is a deterministic, content-addressed scripting language:

- every run produces a SHA-256 receipt
- identical inputs produce identical outputs and identical digests
- execution is replayable across machines and time

Traceability is not a feature. It is an invariant.

The only non-FARD primitive in the composed system is AHD, used by FD. AHD was also authored within the system.

---

## Current Capabilities

- text conversations
- FD payment requests and FD events
- invite-only Qasim objects and commands
- local deterministic Qasim command execution
- SQLite persistence
- conversation retrieval
- message retrieval by digest
- per-message state digests
- delivered, received, and read statuses
- relay transport for offline delivery
- session-authenticated send path
- inbox and unread state
- replay verification

---

## System Architecture

    evidence -> content -> envelope -> wire -> chain -> storage

All transitions are deterministic. All outputs are committed.

---

## Persistence

All state is stored in SQLite:

- messages
- conversations
- statuses
- receipt chain
- Qasim channel permissions
- relay inbox
- identity devices and sessions

On restart:

    chain is loaded -> state continues

---

## Endpoints

### Read

- GET /health
- GET /chain/verify
- GET /replay/verify
- GET /conversations
- GET /conversation/:conversation_id
- GET /conversation/:conversation_id/digest
- GET /message/:content_digest
- GET /qasim/channels
- GET /identity/devices/:root_pk
- GET /identity/sessions/:root_pk
- GET /relay/poll/:recipient_pk
- GET /relay/status/:recipient_pk
- GET /relay/verify
- GET /inbox/:recipient_pk
- GET /inbox/:recipient_pk/unread

### Write

- POST /message/text
- POST /message/payment_request
- POST /message/fd_event
- POST /message/qasim_object
- POST /message/qasim_command
- POST /message/status
- POST /wire/accept
- POST /qasim/invite
- POST /identity/register_device
- POST /identity/register_session
- POST /identity/revoke_session
- POST /relay/send
- POST /relay/ack
- POST /send
- POST /inbox/mark_read

---

## Message Types

- text
- payment_request
- fd_event
- qasim_object, invite-only
- qasim_command, invite-only
- status: delivered, received, read

---

## Qasim Integration

Qasim is a deterministic financial state engine built in FARD.

Inside Messenger:

- Qasim channels are disabled by default
- conversations must be explicitly enabled by invite
- Qasim commands execute locally inside the Messenger bridge
- Qasim state transitions produce `state_digest` and `command_result`

Supported local Qasim commands:

- ingest_fill
- position

Before invite:

    qasim_object -> rejected

After invite:

    qasim_object -> accepted and chained

---

## FD Integration

FD provides deterministic monetary execution:

- deposits
- transfers
- payment requests
- event-based ledger state
- replayable state hashes

---

## Identity Model

    root identity -> deterministic device keys -> session credentials

- root key represents the user
- device keys are derived from `(root_seed, device_id)`
- session keys are issued per device/session
- sessions are revocable
- `/send` requires an active non-revoked session

---

## Relay Model

    sender -> relay -> recipient poll -> wire accept -> receipt chain

- relay stores encrypted `WireMessage`
- relay indexes by `recipient_pk`
- relay cannot decrypt content
- recipient owns execution
- relay has its own verifiable receipt chain

---

## Inbox Model

    inbox = relay_inbox pending + accepted messages

- pending = not-yet-accepted wires
- accepted = messages in receipt chain
- unread = accepted messages without read status

---

## Verification

- GET /chain/verify
- GET /replay/verify
- GET /relay/verify

Guarantees:

- stored chain equals recomputed chain
- relay custody chain verifies
- divergence is detectable

---

## Testing

End-to-end smoke test:

    bash examples/smoke_test.sh

Covers:

- text messaging
- FD events
- read receipts
- Qasim invite gating
- Qasim command execution
- conversation retrieval
- message retrieval
- thread digest
- relay delivery
- inbox unread state
- replay verification
- chain integrity

---

## Releases

### v0.1.0

Messaging spine, FD payments, Qasim channel, SQLite persistence.

- evidence -> content -> signed envelope -> wire message -> receipt chain
- text messages
- FD events
- FD payment requests
- Qasim objects and commands gated per conversation
- SQLite persistence for chain, messages, conversations, statuses, and Qasim permissions
- smoke test 15/15

### v0.2.0

Readable threads, message retrieval, delivery lifecycle, thread digest.

- ordered conversation retrieval
- message retrieval by `content_digest`
- per-message statuses: delivered, received, read
- deterministic thread digest
- replay verification
- smoke test 24/24

### v0.3.0

Local Qasim engine.

- deterministic Qasim command execution inside Messenger bridge
- no external Qasim server dependency for commands
- supported commands: ingest_fill, position
- produces `state_digest` and `command_result`
- state derived only from prior messages

### v0.4.0

Multi-device identity.

- root -> device -> session hierarchy
- deterministic device keys
- session credentials
- revocation
- identity device/session endpoints

### v0.5.0

Relay/network transport.

- encrypted relay inbox
- recipient polling
- relay ack
- relay status
- relay verification
- offline delivery without relay decryption

### v0.6.0

Session-authenticated inbox and offline delivery.

- `/send` uses active session credentials
- inbox combines pending relay wires and accepted messages
- unread state
- mark-read endpoint
- relay verification and replay verification pass together

---

## v0.11.0

Cursor-based relay stream.

- `GET /inbox/:pk/stream` with `{since, next_cursor, messages}`
- `since` = last relay sequence client already observed
- `next_cursor` = highest relay sequence returned
- Stateless: server holds no session state, ordering comes from `relay_inbox.id`
- `poll_model: "cursor-tail"` — client reconnects with `next_cursor` to tail new messages
- Deterministic, replayable, resumable after disconnect

## v0.12.0

Shared Qasim results.

- `command_result` persisted alongside each `finance_qasim` message
- `GET /conversation/:id` surfaces `command_result` and `state_digest` for every Qasim command — both participants see identical results
- `GET /message/:digest` also returns `command_result` when present
- Non-Qasim messages omit the field, no breaking change
- `command_result` is covered by chain verification and replay
- No new message types, no UI rendering decisions, no new commands, no permission changes

---

## Next: v0.13.0 - v0.14.0

### v0.13.0 — encrypted artifact replication

### v0.14.0 — federation between Messenger nodes

---

## License

MUI
