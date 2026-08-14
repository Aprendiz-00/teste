# Network Target Architecture

Migration target:

```text
TCP transport
   |
Connection/session
   |
Legacy WYD protocol adapter
   |
Commands / application layer
   |
Game domains
```

Gameplay code must not depend on HWND, `WSAAsyncSelect` or socket buffer internals after the network phase. The existing client protocol remains supported through the legacy adapter.
