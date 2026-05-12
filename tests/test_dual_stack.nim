## Verifies serve(Port, "::") accepts both IPv4 and IPv6 clients on
## a single socket via IPV6_V6ONLY=0 + IPv4-mapped IPv6.
##
## Counterpart to test_websockets.nim, which exercises the default
## (127.0.0.1) IPv4 path. This one covers the dual-stack opt-in.

import mummy, std/httpclient

var hits: int

proc handler(request: Request) =
  hits += 1
  request.respond(200, body = "ok")

let server = newServer(handler)

var requesterThread: Thread[void]

proc requesterProc() =
  server.waitUntilReady()

  # IPv4 connect to a dual-stack socket — the kernel maps the
  # incoming connection to ::ffff:127.0.0.1 server-side.
  block:
    let client = newHttpClient()
    doAssert client.getContent("http://127.0.0.1:8082/") == "ok"
    client.close()

  # IPv6 connect — direct, no mapping involved.
  block:
    let client = newHttpClient()
    doAssert client.getContent("http://[::1]:8082/") == "ok"
    client.close()

  doAssert hits == 2
  echo "Dual-stack test passed (", hits, " hits)"
  server.close()

createThread(requesterThread, requesterProc)

server.serve(Port(8082), "::")
