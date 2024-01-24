# Ether Deck Mk2

a reasonably optimized, extensible smart account

```mermaid
flowchart LR
    u{{User}}
    e{Ether Deck Mk2}
    r{{Relayer}}

    u --> r
    u -->|call| run --> e
    u -->|call| runBatch --> e
    r -->|call| runFrom --> e
    u -->|call| setDispatch --> e

    e --> mods
    e -->|call| target([Target])

    mods -->|delegate| Flash([FlashMod])
    mods -->|delegate| MassRevoke([MassRevoke])
    mods -->|delegate| MassTransfer([MassTransfer])
```

