module Colonies

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

function client()
    colonies_server = ENV["COLONIES_SERVER_HOST"]
    colonies_port = parse(Int, ENV["COLONIES_SERVER_PORT"])
    colonies_tls = ENV["COLONIES_SERVER_TLS"]
    colonyname = ENV["COLONIES_COLONY_NAME"]
    colony_prvkey = ENV["COLONIES_COLONY_PRVKEY"]
    executorname = ENV["COLONIES_EXECUTOR_NAME"]
    prvkey = ENV["COLONIES_PRVKEY"]

    if colonies_tls == "true"
		client = Colonies.ColoniesClient("https", colonies_server, colonies_port)
    else
		client = Colonies.ColoniesClient("http", colonies_server, colonies_port)
    end

    return client, colonyname, colony_prvkey, executorname, prvkey
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

function addexecutor(client::ColoniesClient, executor::Executor, prvkey::String)
    rpcmsg = AddExecutorRPC(executor, "addexecutormsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addexecutormsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Executor)
end

function addfunction(client::ColoniesClient, func::Function, prvkey::String)
    rpcmsg = AddFunctionRPC(func, "addfunctionmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addfunctionmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Function)
end

function approveexecutor(client::ColoniesClient, colonyname::String, executorname::String, prvkey::String)
    rpcmsg = ApproveExecutorRPC(colonyname, executorname, "approveexecutormsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "approveexecutormsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

function submit(client::ColoniesClient, spec::FunctionSpec, prvkey::String)
    rpcmsg = SubmitFunctionSpecRPC(spec, "submitfuncspecmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "submitfuncspecmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
	unmarshaljson(payload, Process)
end

function addchild(client::ColoniesClient, processgraphid::String, processid::String, spec::FunctionSpec, prvkey::String)
    rpcmsg = AddChildRPC(processgraphid, processid, spec, "addchildmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addchildmsg", payload)

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

function getprocesses(client::ColoniesClient, colonyname::String, state::Int64, count::Int64, prvkey::String)
    rpcmsg = GetProcessesRPC(colonyname, state, count, "getprocessesmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessesmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, AbstractArray{Process})
end

function assign(client::ColoniesClient, colonyname::String, timeout::Int64, prvkey::String)
    rpcmsg = AssignProcessRPC(colonyname, false, timeout, "assignprocessmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "assignprocessmsg", payload)

    try
        payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
        if payloadtype == "assignprocessmsg"
            unmarshaljson(payload, Process)
        elseif payloadtype == "error"
            throw(unmarshaljson(payload, ColoniesError))
        else
            error("invalid payloadtype " * payloadtype)
        end
    catch err
        if err isa ColoniesError && err.status == 404
            nothing
        else
            @info err
            throw(err)
        end
    end
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

function closeprocess(client::ColoniesClient, processid::String, prvkey::String, out::Vector{String}=String[])
    payloadtype = "closesuccessfulmsg"
    rpcmsg = CloseSuccessfulRPC(processid, payloadtype, out)
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, payloadtype, payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

function failprocess(client::ColoniesClient, processid::String, prvkey::String, errors::Vector{String}=String[])
    payloadtype = "closefailedmsg"
    rpcmsg = CloseFailedRPC(processid, payloadtype, errors)
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, payloadtype, payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

function addlog(client::ColoniesClient, processid::String, msg::String, prvkey::String)
    rpcmsg = AddLogRPC(processid, msg, "addlogmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addlogmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
end

function getlogs(client::ColoniesClient, colonyname::String, processid::String, count::Int, since::Int64, prvkey::String)
    rpcmsg = GetLogsRPC(colonyname, processid, "", count, since, "getlogsmsg")
    rpcjson = marshaljson(rpcmsg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getlogsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)

	println(payload)

	unmarshaljson(payload, AbstractArray{Log})
end

function wait(client::ColoniesClient, process::Process, timeout, prvkey)
    state = 2
    msg = Dict(
        "processid" => process.processid,
        "executortype" => process.spec.conditions.executortype,
        "state" => state,
        "timeout" => timeout,
        "colonyname" => process.spec.conditions.colonyname,
        "msgtype" => "subscribeprocessmsg"
    )

    rpcmsg = Dict(
        "payloadtype" => msg["msgtype"],
        "payload" => "",
        "signature" => ""
    )

    rpcmsg["payload"] = Base64.base64encode(JSON.json(msg))
    rpcmsg["signature"] = Crypto.sign(rpcmsg["payload"], prvkey)

    url = ""
    if client.protocol == "https"
        url = "wss://" * client.host * ":" * string(client.port) * "/pubsub"
    else
        url = "ws://" * client.host * ":" * string(client.port) * "/pubsub"
    end

	HTTP.WebSockets.open(url) do ws
        HTTP.WebSockets.send(ws, JSON.json(rpcmsg))
		HTTP.WebSockets.receive(ws)
    end
end

end

