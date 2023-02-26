struct RPCMsg
    signature::String
    payloadtype::String
    payload::String
end

struct AddColonyRPC
    colony::Colony
    msgtype::String
end

struct AddExecutorRPC
    executor::Executor
    msgtype::String
end

struct AddFunctionRPC
    fun::Function
    msgtype::String
end

struct ApproveExecutorRPC
    executorid::String
    msgtype::String
end

struct SubmitFunctionSpecRPC
    spec::FunctionSpec
    msgtype::String
end

struct AddChildRPC
    processgraphid::String
    processid::String
    spec::FunctionSpec
    msgtype::String
end

struct GetProcessRPC
    processid::String
    msgtype::String
end

struct GetProcessesRPC
    colonyid::String
    state::Int64
    count::Int64
    msgtype::String
end

struct AssignProcessRPC
    colonyid::String
    latest::Bool
    timeout::Int64
    msgtype::String
end

struct AddAttributeRPC
    attribute::Attribute
    msgtype::String
end

struct CloseSuccessfulRPC
    processid::String
    msgtype::String
    out::Vector{String}
end

struct CloseFailedRPC
    processid::String
    msgtype::String
    errors::Vector{String}
end

Base.@kwdef mutable struct ColoniesError <: Exception
    message::String
    status::Int64
end

function base64enc(msg::String)
    io = IOBuffer()
    iob64_encode = Base64EncodePipe(io)
    write(iob64_encode, msg)
    close(iob64_encode)
    String(take!(io))
end

function sendrpcmsg(rpcmsg::RPCMsg, protocol::String, host::String, port::Int64)
    url = protocol * "://" * host * ":" * string(port) * "/api"
    body = ""
    try
        r = HTTP.request("POST", url,
            ["Content-Type" => "plain/text"],
            marshaljson(rpcmsg),
            retry_non_idempotent=false,
            retry=false,
            require_ssl_verification=false)
        body = String(r.body)
        rpcreplymsg = unmarshaljson2dict(body)
        payload = String(base64decode(rpcreplymsg["payload"]))
        return payload, rpcreplymsg["payloadtype"]
    catch err
        if isa(err, HTTP.Exceptions.StatusError)
            rpcreplymsg = unmarshaljson2dict(String(err.response.body))
            payload = String(base64decode(rpcreplymsg["payload"]))
            failure_msg = unmarshaljson2dict(payload)
            throw(ColoniesError(failure_msg["message"], failure_msg["status"]))
        else
            @error err
            throw(err)
        end
    end
end
