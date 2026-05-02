# Fard Messenger

Fard Messenger is a deterministic messaging application built entirely in FARD.

It supports normal conversations — text, payments, and commands — while every message is cryptographically verifiable, replayable, and permanently auditable.

Two people — Malik and Samiyah — can text exactly like any modern app. Under the surface, every message produces a chain-linked receipt.

## Core Guarantee

Same messages → same state → same SHA-256 digest.

Every message commits to content, sender, recipient, envelope, execution result, and global chain state.

There is no hidden state, no mutation outside the chain, and no ambiguity.

## What This Is

A messaging app with standard text conversations, payments through FD, financial command execution through Qasim, persistent threads, and verifiable history.

## What Makes It Different

Every conversation is backed by a receipt chain:

    chain_n = SHA256(chain_{n-1}, message, result, state)

This means history cannot be rewritten, state can be independently recomputed, and any third party can verify correctness.

## Built in FARD

Fard Messenger is written entirely in FARD.

FARD is a deterministic, content-addressed scripting language. Every run produces a SHA-256 receipt. Identical inputs produce identical outputs and identical digests. Execution is replayable across machines and time.

Traceability is not a feature. It is an invariant.

## Qasim Integration — Invite Only

Qasim is a deterministic financial state engine built in FARD.

Inside Messenger, Qasim messages are disabled by default. Conversations must be explicitly enabled by invite. Only invited conversations can exchange Qasim objects and Qasim commands.

Before invite: qasim_object is rejected.
After invite: qasim_object is accepted and chained.

## Message Types

- text
- payment_request
- fd_event
- qasim_object, invite only
- qasim_command, invite only

## Persistence

All state is stored in SQLite: messages, conversations, and receipt chain.

On restart, the chain is loaded and state continues.

## Endpoints

Read:

- GET /health
- GET /chain/verify
- GET /conversations
- GET /conversation/<conversation_id>
- GET /qasim/channels
- GET /replay/verify

Write:

- POST /message/text
- POST /message/payment_request
- POST /message/fd_event
- POST /message/qasim_object
- POST /message/qasim_command
- POST /wire/accept
- POST /qasim/invite

## Conversation Model

Conversation identity:

    conversation_id = pk_a : pk_b

Each message increments sequence, updates chain head, persists to SQLite, and remains replay-verifiable.

## Verification

- GET /chain/verify
- GET /replay/verify

Guarantee: stored chain equals recomputed chain.

## System Architecture

    evidence → content → envelope → wire → chain → storage

## FD — Fard Dinar

FD provides deterministic monetary execution: deposits, transfers, balances, event-based state, and replayable ledger computation.

## AHD

The only non-FARD primitive is AHD, used in FD. AHD was also authored within the system. It is deterministic, fully specified, and used strictly as a cryptographic primitive.

## Status

- message spine complete
- persistence complete
- Qasim gating complete
- replay verification complete
- HTTP messaging operational
- multi-message conversation chaining operational

## License

MUI
