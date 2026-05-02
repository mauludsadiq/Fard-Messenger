# Messenger Finance Spec

## Channels

- `finance_qasim`: Qasim signed objects, commands, audit bundles, replay exports.
- `finance_fd`: FD deposits, transfers, payment requests, registry snapshots, receipts.

## Canonical chain

```text
Evidence → Content → content_digest → SignedEnvelope → WireMessage → ReceiptChain
```

## Engine separation

Messenger verifies and routes. Qasim and FD compute their own financial state. Messenger keeps the communication state, transport chain, and route-level digest commitments.
