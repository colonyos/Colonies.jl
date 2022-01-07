module Colonies
include("./rpc.jl")

using JSON
using JSON2
using HTTP
using Base64

function addcolony(colony::Colony, prvkey::String) 
  addcolonyrpc = AddColonyRPC(colony, "addcolonymsg")
  rpcjson = JSON.json(addcolonyrpc)

  payload = base64encode(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "addcolonymsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Colony)
end

end
