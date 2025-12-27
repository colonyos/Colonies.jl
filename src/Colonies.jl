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
    # Use minimal dict format like Python SDK
    executor_dict = Dict(
        "executorname" => executor.executorname,
        "executorid" => executor.executorid,
        "colonyname" => executor.colonyname,
        "executortype" => executor.executortype
    )
    msg = Dict(
        "msgtype" => "addexecutormsg",
        "executor" => executor_dict
    )
    rpcjson = JSON.json(msg)

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
    # Build conditions dict
    conditions_dict = Dict{String, Any}(
        "colonyname" => spec.conditions.colonyname,
        "executortype" => spec.conditions.executortype
    )
    if !isempty(spec.conditions.executornames)
        conditions_dict["executornames"] = spec.conditions.executornames
    end
    if !isempty(spec.conditions.dependencies)
        conditions_dict["dependencies"] = spec.conditions.dependencies
    end

    # Build spec dict
    spec_dict = Dict{String, Any}(
        "nodename" => spec.nodename,
        "funcname" => spec.funcname,
        "args" => spec.args === nothing ? [] : spec.args,
        "kwargs" => spec.kwargs,
        "priority" => spec.priority,
        "maxwaittime" => spec.maxwaittime,
        "maxexectime" => spec.maxexectime,
        "maxretries" => spec.maxretries,
        "conditions" => conditions_dict,
        "label" => spec.label,
        "env" => spec.env
    )

    msg = Dict(
        "msgtype" => "submitfuncspecmsg",
        "spec" => spec_dict
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "submitfuncspecmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_process_result(payload)
end

# Helper to parse process response into ProcessResult
function parse_process_result(payload::String)
    dict = JSON.parse(payload)
    result = ProcessResult()
    result.processid = get(dict, "processid", "")
    result.state = get(dict, "state", 0)
    result.spec = get(dict, "spec", Dict{String, Any}())
    result.output = get(dict, "out", [])
    result.errors = get(dict, "errors", [])
    result
end

function addchild(client::ColoniesClient, processgraphid::String, processid::String, spec::FunctionSpec, prvkey::String)
    # Build conditions dict
    conditions_dict = Dict{String, Any}(
        "colonyname" => spec.conditions.colonyname,
        "executortype" => spec.conditions.executortype
    )

    # Build spec dict
    spec_dict = Dict{String, Any}(
        "nodename" => spec.nodename,
        "funcname" => spec.funcname,
        "args" => spec.args === nothing ? [] : spec.args,
        "kwargs" => spec.kwargs,
        "priority" => spec.priority,
        "maxwaittime" => spec.maxwaittime,
        "maxexectime" => spec.maxexectime,
        "maxretries" => spec.maxretries,
        "conditions" => conditions_dict,
        "label" => spec.label,
        "env" => spec.env
    )

    msg = Dict(
        "msgtype" => "addchildmsg",
        "processgraphid" => processgraphid,
        "parentprocessid" => processid,
        "childprocessid" => "",
        "spec" => spec_dict,
        "insert" => false
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addchildmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_process_result(payload)
end

function getprocess(client::ColoniesClient, processid::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getprocessmsg",
        "processid" => processid
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_process_result(payload)
end

function getprocesses(client::ColoniesClient, colonyname::String, state::Int64, count::Int64, prvkey::String)
    msg = Dict(
        "msgtype" => "getprocessesmsg",
        "colonyname" => colonyname,
        "state" => state,
        "count" => count
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessesmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    # Parse array of processes
    arr = JSON.parse(payload)
    if arr === nothing
        return ProcessResult[]
    end
    [parse_process_dict(p) for p in arr]
end

# Helper to parse a single process dict
function parse_process_dict(dict::AbstractDict)
    result = ProcessResult()
    result.processid = get(dict, "processid", "")
    result.state = get(dict, "state", 0)
    result.spec = get(dict, "spec", Dict{String, Any}())
    result.output = get(dict, "out", [])
    result.errors = get(dict, "errors", [])
    result
end

function assign(client::ColoniesClient, colonyname::String, timeout::Int64, prvkey::String)
    msg = Dict(
        "msgtype" => "assignprocessmsg",
        "colonyname" => colonyname,
        "latest" => false,
        "timeout" => timeout
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "assignprocessmsg", payload)

    try
        payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
        if payloadtype == "assignprocessmsg"
            parse_process_result(payload)
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

# ============================================================================
# Colony Management
# ============================================================================

function getcolony(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getcolonymsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getcolonymsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Colony)
end

function getcolonies(client::ColoniesClient, prvkey::String)
    msg = Dict(
        "msgtype" => "getcoloniesmsg"
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getcoloniesmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return Colony[]
    end
    [unmarshaljson(JSON.json(c), Colony) for c in arr]
end

function removecolony(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removecolonymsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removecolonymsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

# ============================================================================
# Executor Management
# ============================================================================

function getexecutor(client::ColoniesClient, colonyname::String, executorname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getexecutormsg",
        "colonyname" => colonyname,
        "executorname" => executorname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getexecutormsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    unmarshaljson(payload, Executor)
end

function getexecutors(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getexecutorsmsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getexecutorsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return Executor[]
    end
    [unmarshaljson(JSON.json(e), Executor) for e in arr]
end

function rejectexecutor(client::ColoniesClient, colonyname::String, executorname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "rejectexecutormsg",
        "colonyname" => colonyname,
        "executorname" => executorname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "rejectexecutormsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function removeexecutor(client::ColoniesClient, colonyname::String, executorname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removeexecutormsg",
        "colonyname" => colonyname,
        "executorname" => executorname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeexecutormsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

# ============================================================================
# Process Management
# ============================================================================

function removeprocess(client::ColoniesClient, processid::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removeprocessmsg",
        "processid" => processid,
        "all" => false
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeprocessmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function removeallprocesses(client::ColoniesClient, colonyname::String, prvkey::String; state::Int64=-1)
    msg = Dict(
        "msgtype" => "removeallprocessesmsg",
        "colonyname" => colonyname,
        "state" => state
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeallprocessesmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function setoutput(client::ColoniesClient, processid::String, output::Vector, prvkey::String)
    msg = Dict(
        "msgtype" => "setoutputmsg",
        "processid" => processid,
        "out" => output
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "setoutputmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

# ============================================================================
# Workflow/ProcessGraph Management
# ============================================================================

function submitworkflow(client::ColoniesClient, colonyname::String, functionspecs::Vector{FunctionSpec}, prvkey::String)
    specs_arr = []
    for spec in functionspecs
        conditions_dict = Dict{String, Any}(
            "colonyname" => spec.conditions.colonyname,
            "executortype" => spec.conditions.executortype
        )
        if !isempty(spec.conditions.executornames)
            conditions_dict["executornames"] = spec.conditions.executornames
        end
        if !isempty(spec.conditions.dependencies)
            conditions_dict["dependencies"] = spec.conditions.dependencies
        end

        spec_dict = Dict{String, Any}(
            "nodename" => spec.nodename,
            "funcname" => spec.funcname,
            "args" => spec.args === nothing ? [] : spec.args,
            "kwargs" => spec.kwargs,
            "priority" => spec.priority,
            "maxwaittime" => spec.maxwaittime,
            "maxexectime" => spec.maxexectime,
            "maxretries" => spec.maxretries,
            "conditions" => conditions_dict,
            "label" => spec.label,
            "env" => spec.env
        )
        push!(specs_arr, spec_dict)
    end

    workflow = Dict(
        "colonyname" => colonyname,
        "functionspecs" => specs_arr
    )

    msg = Dict(
        "msgtype" => "submitworkflowspecmsg",
        "workflow" => workflow
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "submitworkflowspecmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_processgraph(payload)
end

function parse_processgraph(payload::String)
    dict = JSON.parse(payload)
    ProcessGraph(
        get(dict, "processgraphid", ""),
        get(dict, "colonyname", ""),
        get(dict, "state", 0),
        get(dict, "rootprocessids", String[]),
        get(dict, "processids", String[])
    )
end

function getprocessgraph(client::ColoniesClient, processgraphid::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getprocessgraphmsg",
        "processgraphid" => processgraphid
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessgraphmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_processgraph(payload)
end

function getprocessgraphs(client::ColoniesClient, colonyname::String, count::Int64, prvkey::String; state::Int64=-1)
    msg = Dict(
        "msgtype" => "getprocessgraphsmsg",
        "colonyname" => colonyname,
        "count" => count,
        "state" => state
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getprocessgraphsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return ProcessGraph[]
    end
    [parse_processgraph(JSON.json(pg)) for pg in arr]
end

function removeprocessgraph(client::ColoniesClient, processgraphid::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removeprocessgraphmsg",
        "processgraphid" => processgraphid
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeprocessgraphmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function removeallprocessgraphs(client::ColoniesClient, colonyname::String, prvkey::String; state::Int64=-1)
    msg = Dict(
        "msgtype" => "removeallprocessgraphsmsg",
        "colonyname" => colonyname,
        "state" => state
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeallprocessgraphsmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

# ============================================================================
# Functions
# ============================================================================

function getfunctions(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getfunctionsmsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getfunctionsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return Function[]
    end
    [unmarshaljson(JSON.json(f), Function) for f in arr]
end

# ============================================================================
# Statistics
# ============================================================================

function getstats(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getstatisticsmsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getstatisticsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    dict = JSON.parse(payload)
    Statistics(
        get(dict, "colonies", 0),
        get(dict, "executors", 0),
        get(dict, "waitingprocesses", 0),
        get(dict, "runningprocesses", 0),
        get(dict, "successfulprocesses", 0),
        get(dict, "failedprocesses", 0),
        get(dict, "waitingworkflows", 0),
        get(dict, "runningworkflows", 0),
        get(dict, "successfulworkflows", 0),
        get(dict, "failedworkflows", 0)
    )
end

# ============================================================================
# Channels
# ============================================================================

function channelappend(client::ColoniesClient, processid::String, channel_name::String, sequence::Int64, data::String, prvkey::String; msgtype::String="data", inreplyto::Int64=0)
    msg = Dict(
        "msgtype" => "channelappendmsg",
        "processid" => processid,
        "name" => channel_name,
        "sequence" => sequence,
        "data" => data,
        "type" => msgtype,
        "inreplyto" => inreplyto
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "channelappendmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function channelread(client::ColoniesClient, processid::String, channel_name::String, after_seq::Int64, limit::Int64, prvkey::String)
    msg = Dict(
        "msgtype" => "channelreadmsg",
        "processid" => processid,
        "name" => channel_name,
        "afterseq" => after_seq,
        "limit" => limit
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "channelreadmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return ChannelEntry[]
    end
    entries = ChannelEntry[]
    for entry in arr
        push!(entries, ChannelEntry(
            get(entry, "sequence", 0),
            get(entry, "data", ""),
            get(entry, "type", "data"),
            get(entry, "inreplyto", 0)
        ))
    end
    entries
end

# ============================================================================
# Blueprint Definitions
# ============================================================================

function addblueprintdefinition(client::ColoniesClient, definition::BlueprintDefinition, prvkey::String)
    def_dict = Dict(
        "name" => definition.name,
        "colonyname" => definition.colonyname,
        "kind" => definition.kind,
        "executortype" => definition.executortype,
        "specschema" => definition.specschema,
        "statusschema" => definition.statusschema
    )
    msg = Dict(
        "msgtype" => "addblueprintdefinitionmsg",
        "blueprintdefinition" => def_dict
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addblueprintdefinitionmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_blueprintdefinition(payload)
end

function parse_blueprintdefinition(payload::String)
    dict = JSON.parse(payload)
    BlueprintDefinition(
        get(dict, "name", ""),
        get(dict, "colonyname", ""),
        get(dict, "kind", ""),
        get(dict, "executortype", ""),
        get(dict, "specschema", Dict{String, Any}()),
        get(dict, "statusschema", Dict{String, Any}())
    )
end

function getblueprintdefinition(client::ColoniesClient, colonyname::String, name::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getblueprintdefinitionmsg",
        "colonyname" => colonyname,
        "name" => name
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getblueprintdefinitionmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_blueprintdefinition(payload)
end

function getblueprintdefinitions(client::ColoniesClient, colonyname::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getblueprintdefinitionsmsg",
        "colonyname" => colonyname
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getblueprintdefinitionsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return BlueprintDefinition[]
    end
    [parse_blueprintdefinition(JSON.json(d)) for d in arr]
end

function removeblueprintdefinition(client::ColoniesClient, colonyname::String, name::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removeblueprintdefinitionmsg",
        "colonyname" => colonyname,
        "name" => name
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeblueprintdefinitionmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

# ============================================================================
# Blueprints
# ============================================================================

function addblueprint(client::ColoniesClient, blueprint::Blueprint, prvkey::String)
    bp_dict = Dict(
        "kind" => blueprint.kind,
        "metadata" => Dict(
            "name" => blueprint.metadata.name,
            "colonyname" => blueprint.metadata.colonyname
        ),
        "handler" => Dict(
            "executortype" => blueprint.handler.executortype
        ),
        "spec" => blueprint.spec,
        "status" => blueprint.status
    )
    msg = Dict(
        "msgtype" => "addblueprintmsg",
        "blueprint" => bp_dict
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "addblueprintmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_blueprint(payload)
end

function parse_blueprint(payload::String)
    dict = JSON.parse(payload)
    metadata_dict = get(dict, "metadata", Dict{String, Any}())
    handler_dict = get(dict, "handler", Dict{String, Any}())
    Blueprint(
        get(dict, "blueprintid", ""),
        get(dict, "kind", ""),
        BlueprintMetadata(
            get(metadata_dict, "name", ""),
            get(metadata_dict, "colonyname", "")
        ),
        BlueprintHandler(
            get(handler_dict, "executortype", "")
        ),
        get(dict, "spec", Dict{String, Any}()),
        get(dict, "status", Dict{String, Any}()),
        get(dict, "generation", 0),
        get(dict, "reconciledgeneration", 0),
        get(dict, "lastreconciled", "")
    )
end

function getblueprint(client::ColoniesClient, colonyname::String, name::String, prvkey::String)
    msg = Dict(
        "msgtype" => "getblueprintmsg",
        "colonyname" => colonyname,
        "name" => name
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getblueprintmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_blueprint(payload)
end

function getblueprints(client::ColoniesClient, colonyname::String, prvkey::String; kind::String="", location::String="")
    msg = Dict(
        "msgtype" => "getblueprintsmsg",
        "colonyname" => colonyname,
        "kind" => kind,
        "location" => location
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "getblueprintsmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    arr = JSON.parse(payload)
    if arr === nothing
        return Blueprint[]
    end
    [parse_blueprint(JSON.json(bp)) for bp in arr]
end

function updateblueprint(client::ColoniesClient, blueprint::Blueprint, prvkey::String; forcegeneration::Bool=false)
    bp_dict = Dict(
        "blueprintid" => blueprint.blueprintid,
        "kind" => blueprint.kind,
        "metadata" => Dict(
            "name" => blueprint.metadata.name,
            "colonyname" => blueprint.metadata.colonyname
        ),
        "handler" => Dict(
            "executortype" => blueprint.handler.executortype
        ),
        "spec" => blueprint.spec,
        "status" => blueprint.status
    )
    msg = Dict(
        "msgtype" => "updateblueprintmsg",
        "blueprint" => bp_dict,
        "forcegeneration" => forcegeneration
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "updateblueprintmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_blueprint(payload)
end

function removeblueprint(client::ColoniesClient, colonyname::String, name::String, prvkey::String)
    msg = Dict(
        "msgtype" => "removeblueprintmsg",
        "colonyname" => colonyname,
        "name" => name
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "removeblueprintmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function updateblueprintstatus(client::ColoniesClient, colonyname::String, name::String, status::Dict{String, Any}, prvkey::String)
    msg = Dict(
        "msgtype" => "updateblueprintstatusmsg",
        "colonyname" => colonyname,
        "name" => name,
        "status" => status
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "updateblueprintstatusmsg", payload)

    sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    nothing
end

function reconcileblueprint(client::ColoniesClient, colonyname::String, name::String, prvkey::String; force::Bool=false)
    msg = Dict(
        "msgtype" => "reconcileblueprintmsg",
        "colonyname" => colonyname,
        "name" => name,
        "force" => force
    )
    rpcjson = JSON.json(msg)

    payload = base64enc(rpcjson)
    sig = Crypto.sign(payload, prvkey)
    rpcmsg = RPCMsg(sig, "reconcileblueprintmsg", payload)

    payload, payloadtype = sendrpcmsg(rpcmsg, client.protocol, client.host, client.port)
    parse_process_result(payload)
end

end

