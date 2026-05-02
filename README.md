# Fard Messenger

Fard Messenger is a messaging app where every message can execute real systems and produce a verifiable state.

Malik and Samiyah can have a normal conversation.  
But when a message carries intent — money, trades, or state updates — it is executed, verified, and committed.

---

## Core Model

text message → envelope → execution → state → receipt → chain 

Each message is:

- signed  
- executed  
- reduced to a deterministic state  
- committed into a cryptographic chain  

---

## System Integration

## Built in FARD

Fard Messenger is FARD-native.

The messaging layer, dispatch spine, envelopes, bridges, receipt chain, FD integration, and Qasim integration are all written in FARD.

The composed system is:

```text
Messenger → FARD
Fard Dinar → FARD
Qasim → FARD
Receipt Chain → FARD
```

The only non-FARD executable dependency in the current composed stack is **AHD-1024**, used by Fard Dinar for hashing. AHD-1024 was also written by the same author.

This means the system is not a conventional app stitched together with opaque services. It is a deterministic FARD execution stack where messages, money movement, financial state, and receipts are all produced through auditable code.


### Fard Dinar (FD)

- Deterministic monetary execution  
- Deposits, transfers, balances  
- Produces canonical state hashes  

---

### Qasim (Invite Only)

- Deterministic, cryptographically verifiable financial state engine  
- Ingests signed financial events (fills, cash, instruments, prices)  
- Computes full portfolio state:

  - positions (multi-asset)
  - NAV (public + private)
  - risk (VaR, ES, Greeks, DV01)
  - compliance
  - liquidity

- Produces:

  - state_digest
  - verification_digest
  - replayable state  

Guarantee:

text same inputs → same state_digest → independently verifiable 

No hidden state. No ambiguity. No reconciliation.

---

## Conversation → Execution

text Malik: "Deposit $100" → FD executes deposit  Samiyah: "Send me $25" → FD executes transfer  System: → Qasim recomputes full financial state → outputs verified state_digest → commits both steps into chain 

Result:

text GENESIS   → fd_deposit   → fd_transfer 

Each step includes:

- payload digest  
- resulting state digest  
- chain linkage  

---

## What This Enables

- Messaging + execution in one system  
- No gap between intent and outcome  
- Full state after every message  
- Deterministic replay of any conversation  

---

## Current State

text Messaging → operational FD → integrated Qasim → integrated (invite only) Dispatch spine → operational Receipt chain → operational Multi-message conversations → operational 

---

## Invariant

> Every message produces a state.  
> Every state has a digest.  
> Every digest is reproducible.  
> Every conversation is a chain.

---

## License

MUI