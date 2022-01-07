module ColonyRuntime 
include("./core.jl")
include("./rpc.jl")
include("./Crypto.jl")

import .Crypto

using JSON
using JSON2
using HTTP
using Base64

struct ColoniesServer
  host::String
  port::Int64
end

function addcolony(server::ColoniesServer, colony::Colony, prvkey::String) 
  rpcmsg = AddColonyRPC(colony, "addcolonymsg")
  rpcjson = JSON2.write(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "addcolonymsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Colony)
end

function addruntime(server::ColoniesServer, runtime::Runtime, prvkey::String)
  rpcmsg = AddRuntimeRPC(runtime, "addruntimemsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "addruntimemsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Runtime)
end

function approveruntime(server::ColoniesServer, runtimeid::String, prvkey::String)
  rpcmsg = ApproveRuntimeRPC(runtimeid, "approveruntimemsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "approveruntimemsg", payload)

  sendrpcmsg(rpcmsg)
end

function submitprocess(server::ColoniesServer, spec::ProcessSpec, prvkey::String)
  rpcmsg = SubmitProcessSpecRPC(spec, "submitprocessespecmsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "submitprocessespecmsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Process)
end

function getprocess(server::ColoniesServer, processid::String, prvkey::String)
  rpcmsg = GetProcessRPC(processid, "getprocessmsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "getprocessmsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Process)
end

function assignprocess(server::ColoniesServer, colonyid::String, prvkey::String)
  rpcmsg = AssignProcessRPC(colonyid, "assignprocessmsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "assignprocessmsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Process)
end

function addattribute(server::ColoniesServer, attribute::Attribute, prvkey::String)
  rpcmsg = AddAttributeRPC(attribute, "addattributemsg")
  rpcjson = JSON.json(rpcmsg)

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, "addattributemsg", payload)

  payload, payloadtype = sendrpcmsg(rpcmsg)
  JSON2.read(payload, Attribute)
end

function closeprocess(server::ColoniesServer, processid::String, successful::Bool, prvkey::String)
  payloadtype = "closesuccessfulmsg"
  rpcmsg = CloseSuccessfulRPC(processid, payloadtype)
  rpcjson = JSON.json(rpcmsg)
  
  if !successful
    payloadtype = "closefailedmsg"
    rpcmsg = CloseSuccessfulRPC(processid, payloadtype)
    rpcjson = JSON.json(rpcmsg)
  end

  payload = base64enc(rpcjson)
  sig = Crypto.sign(payload, prvkey)
  rpcmsg = RPCMsg(sig, payloadtype, payload)

  sendrpcmsg(rpcmsg)
end

end
