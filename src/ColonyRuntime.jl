module ColonyRuntime
include("./core.jl")
include("./json.jl")
include("./rpc.jl")
include("./Crypto.jl")

import .Crypto

using HTTP
using Base64

struct ColoniesClient
    protocol::String
    host::String
    port::Int64
end

function addcolony(client::ColoniesClient, colony::Colony, prvkey::String)
    rpcmsg = AddColonyRPC(colony, "addcolonymsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addcolonymsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Colony)
end

function addruntime(client::ColoniesClient, runtime::Runtime, prvkey::String)
    rpcmsg = AddRuntimeRPC(runtime, "addruntimemsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addruntimemsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Runtime)
end

function approveruntime(client::ColoniesClient, runtimeid::String, prvkey::String)
    rpcmsg = ApproveRuntimeRPC(runtimeid, "approveruntimemsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "approveruntimemsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

function submitprocess(client::ColoniesClient, spec::ProcessSpec, prvkey::String)
    rpcmsg = SubmitProcessSpecRPC(spec, "submitprocessespecmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "submitprocessespecmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Process)
end

function getprocess(client::ColoniesClient, processid::String, prvkey::String)
    rpcmsg = GetProcessRPC(processid, "getprocessmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Process)
end

function getprocesses(client::ColoniesClient, colonyid::String, state::Int64, count::Int64, prvkey::String)
    rpcmsg = GetProcessesRPC(colonyid, state, count, "getprocessesmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessesmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, AbstractArray{Process})
end

function assignprocess(client::ColoniesClient, colonyid::String, timeout::Int64, prvkey::String)
    rpcmsg = AssignProcessRPC(colonyid, false, timeout, "assignprocessmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "assignprocessmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Process)
end

function addattribute(client::ColoniesClient, attribute::Attribute, prvkey::String)
    rpcmsg = AddAttributeRPC(attribute, "addattributemsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addattributemsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Attribute)
end

function closeprocess(client::ColoniesClient, processid::String, successful::Bool, prvkey::String)
    payloadtype = "closesuccessfulmsg"
    rpcmsg = CloseSuccessfulRPC(processid, payloadtype)
    rpcjson = marshaljson(rpcmsg)

    if !successful
        payloadtype = "closefailedmsg"
        rpcmsg = CloseSuccessfulRPC(processid, payloadtype)
        rpcjson = marshaljson(rpcmsg)
    end

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, payloadtype, payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

end
