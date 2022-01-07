#include("./WebSockets.jl/src/WebSockets.jl")
using WebSockets
#import HTTP.Servers: MbedTLS 

#import HTTP.Servers: MbedTLS                # For further imports
#import HTTP.Servers.MbedTLS:SSLConfig

#using HTTP, MbedTLS
#client = HTTP.Client(tlsconfig=MbedTLS.SSLConfig(false))
#HTTP.get(client, url; options...)

#sslconf = WebSockets.SSLConfig(cert, key)
#ServerWS(h,w, sslconfig = sslconf)

#tlsconfig = MbedTLS.SSLConfig("cert.pem", "key.pem")
#tlsconfig = WebSocket.SSLConfig("cert.pem", "cert_key.pem")

#require_ssl_verification = false
#HTTP.request("GET", "https://localhost:8080", require_ssl_verification = true)

#print(WebSocket)
#print(WebSCoket)

#WebSockets.default_options().sslconfig = tlsconfig

Base.exit_on_sigint(false)

try
  WebSockets.open("wss://127.0.0.1:8080/ws", require_ssl_verification=false) do ws
    writeguarded(ws, "hej")
    msg, stillopen = readguarded(ws)
    println("Received:", String(msg))
    if stillopen
      println("The connection is active, but we leave. WebSockets.jl will close properly.")
    else
      println("Disconnect during reading.")
    end
  end
catch err
  typeof(err) == InterruptException && rethrow(err)
  print(err)
end
#  data, success = readguarded(ws_client)
#  if success
#    println("received:", String(data))
#  end
