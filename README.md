# Fard Messenger

Fard Messenger is a deterministic messaging application built entirely in FARD.

It supports normal conversations — text, payments, and commands — while every message is cryptographically verifiable, replayable, and permanently auditable.

Two people — Malik and Samiyah — can text exactly like any modern app. Under the surface, every message produces a chain-linked receipt.

---

## Core Guarantee

Same messages → same state → same SHA-256 digest.

Every message commits to content, sender, recipient, envelope, execution result, and global chain state.

There is no hidden state, no mutation outside the chain, and no ambiguity.

---

## What This Is

A messaging app with:
- text conversations
- payments (FD)
- financial execution (Qasim)
- persistent threads
- verifiable history

---

## What Makes It Different

Every conversation is backed by a receipt chain:

    chain_n = SHA256(chain_{n-1}, message, result, state)

This means:
- history cannot be rewritten
- state can be independently recomputed
- any third party can verify correctness

---

## Built in FARD

Fard Messenger is written entirely in FARD.

FARD is a deterministic, content-addressed scripting language:

- every run produces a SHA-256 receipt
- identical inputs produce identical outputs and identical digests
- execution is replayable across machines and time

Traceability is not a feature. It is an invariant.

---

## Qasim Integration (Invite-Only)

Qasim is a deterministic financial state engine built in FARD.

Inside Messenger:
- disabled by default
- enabled per conversation via invite
- only invited conversations can exchange Qasim objects and commands

    POST /qasim/invite

Before invite:
    qasim_object → rejected

After invite:
    qasim_object → accepted and chained

---

## Message Types

- text
- payment_request
- fd_event
- qasim_object (invite-only)
- qasim_command (invite-only)
- status (read / delivered / received)

---

## Persistence

All state is stored in SQLite:
- messages
- conversations
- statuses
- receipt chain

On restart:
    chain is loaded → state continues

---

## Endpoints

### Read

- GET /health
- GET /chain/verify
- GET /replay/verify
- GET /conversations
- GET /conversation/<conversation_id>
- GET /qasim/channels

### Write

- POST /message/text
- POST /message/payment_request
- POST /message/fd_event
- POST /message/qasim_object
- POST /message/qasim_command
- POST /message/status
- POST /wire/accept
- POST /qasim/invite

---

## Conversation Model

    conversation_id = pk_a : pk_b

Each message:
- increments sequence
- updates chain head
- persists to SQLite
- produces a state_digest
- can carry statuses (read, delivered, received)

---

## Verification

- GET /chain/verify
- GET /replay/verify

Guarantee:
- stored chain == recomputed chain
- divergence is detectable

---

## System Architecture

    evidence → content → envelope → wire → chain → storage

All transitions are deterministic. All outputs are committed.

---

## FD (Fard Dinar)

- deterministic monetary execution
- event-based ledger
- replayable state
- integrated into messaging

---

## AHD

The only non-FARD primitive is AHD (used in FD).

- authored within the system
- deterministic
- fully specified

---

## Testing

End-to-end smoke test:

    bash examples/smoke_test.sh

Covers:
- text messaging
- FD events
- read receipts
- Qasim invite gating
- conversation retrieval
- replay verification
- chain integrity

---

## Status

- message spine complete
- persistence complete
- replay verification complete
- Qasim gating complete
- per-message state_digest
- read receipts
- end-to-end test coverage

---

---

## v0.2.0

Readable threads and delivery lifecycle.

- `GET /conversation/:id` returns ordered messages
- `GET /message/:content_digest` retrieves a message by digest
- messages include `seq`, `channel`, `content_digest`, and `state_digest`
- statuses are stored per message: `delivered`, `received`, `read`
- `GET /conversation/:id/digest` returns the deterministic thread digest
- `GET /replay/verify` recomputes the persisted chain and confirms `stored_head == computed_head`
- `examples/smoke_test.sh` verifies the full flow

Smoke test: 24/24.



---

## v0.4.0

Deterministic multi-device identity with session credentials.

### Identity Model

root identity → deterministic device keys → session credentials

- root key represents the user
- device keys are deterministically derived from `(root_seed, device_id)`
- session keys are issued per device/session and signed by the device

### Devices

- `POST /identity/register_device`
- deterministic `device_pk`
- signed by root
- revocable

### Sessions

- `POST /identity/register_session`
- session key bound to device
- device-signed credential
- revocable via `POST /identity/revoke_session`

### Queries

- `GET /identity/devices/:root_pk`
- `GET /identity/sessions/:root_pk`

### Properties

- no coordination required for device derivation
- explicit revocation for sessions
- supports multi-device identity
- compatible with deterministic replay model

### Next

- require active (non-revoked) session for message send
- bind messages to `session_pk`
- verify session chain during replay


## License

MUI
