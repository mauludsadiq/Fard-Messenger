# FARD Messenger

FARD Messenger is a deterministic financial message rail written in FARD.

It embeds two operational financial systems as message channels:

- **Qasim** — deterministic financial valuation, risk, compliance, and audit state.
- **Fard Dinar** — deterministic monetary ledger, payment request, transfer, deposit, and receipt state.

Messenger is not a replacement for either engine. It is the envelope, transport, identity, content-addressing, receipt-chain, and routing layer that carries their signed canonical payloads.

```text
Evidence → Content → content_digest → Envelope → WireMessage → ReceiptChain → Engine Bridge
```

## Guarantees

- Canonical message objects.
- Deterministic digest construction.
- Append-only receipt chain.
- Engine-specific payload validation before routing.
- Content-addressed blob/object storage.
- Transport abstraction with in-memory and HTTP-style message queues.
- Qasim payload channel for signed fills, cash, orders, instruments, price claims, compliance rules, audit bundles, and replay exports.
- Fard Dinar payload channel for deposits, transfers, fdpay requests, registry snapshots, receipts, and ledger exports.

## Layout

```text
main.fard
packages/
  messenger_core/       content, evidence, digest, envelope, wire, CAS, receipt chain
  messenger_identity/   deterministic identities, signatures, RBAC
  messenger_transport/  memory/http/relay transport semantics
  messenger_qasim/      Qasim payload validation and routing bridge
  messenger_fd/         Fard Dinar payload validation and routing bridge
  messenger_http/       request router and handlers
tests/                  executable FARD tests
examples/               canonical demo messages
```

## Run

```bash
fardrun run --program main.fard --out /tmp/fard_messenger
```

## Test

```bash
fardrun test --program tests/test_messenger_core.fard
fardrun test --program tests/test_qasim_messages.fard
fardrun test --program tests/test_fd_messages.fard
fardrun test --program tests/test_receipt_chain.fard
fardrun test --program tests/test_replay_convergence.fard
```

## Canonical model

```text
Messenger carries facts.
Qasim computes financial state.
Fard Dinar computes monetary state.
FARD makes every execution replayable.
Receipts make every transition auditable.
```
