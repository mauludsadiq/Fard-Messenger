# Fard Messenger

A messaging app where you can text people and pay them in the same conversation.

Think iMessage with a built-in wallet. You send a message, tap +, send money. The recipient gets both in the same thread, in order, with a cryptographic receipt on every message.

## Payments

Payments are first-class messages. A payment request looks like a message. A transfer looks like a message. Everything is in the thread.

The payment layer is [Fard Dinar](https://github.com/mauludsadiq/Fard-Dinar) — a deterministic monetary engine where every deposit, transfer, and ledger state is reproducible from the event log alone. Same inputs, same machine or different, identical result every time.

Institutional conversations can connect to [Qasim](https://github.com/mauludsadiq/Qasim-in-FARD) — a financial state engine for signed order flow, position tracking, risk, and audit trails. Available by invitation only.

Both engines are written in [FARD](https://github.com/mauludsadiq/FARD) — a deterministic scripting language where every execution produces a SHA-256 receipt committing to inputs, code, and outputs. So is Messenger itself.

## Run

    fardrun run --program main.fard --out /tmp/fard_messenger

## What a conversation looks like

    Alice -> Bob   "Hey, want to split the bill?"
    Alice -> Bob   [payment request: 2500 FD, dinner]
    Bob   -> Alice "Sure, paying now"
    Bob   -> Alice [transfer: 2500 FD]

Every message: signed by sender, encrypted for recipient, appended to a tamper-evident chain.

## Layout

    main.fard
    packages/
      messenger_core/       digest, content, evidence, envelope, wire, CAS, chain
      messenger_identity/   keys, signatures, RBAC
      messenger_transport/  memory, HTTP, relay
      messenger_fd/         Fard Dinar payment channel
      messenger_qasim/      Qasim financial channel (invited only)
      messenger_http/       routes and handlers
      messenger_exec/       dispatch, engine bridges, receipt chain
    tests/
    examples/
