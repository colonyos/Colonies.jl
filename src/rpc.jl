struct RPCMsg
    signature::String
    payloadtype::String
    payload::String
end

struct AddColonyRPC
    colony::Colony
    msgtype::String
end

struct AddRuntimeRPC
    runtime::Runtime
    msgtype::String
end

struct ApproveRuntimeRPC
    runtimeid::String
    msgtype::String
end

struct SubmitProcessSpecRPC
    spec::ProcessSpec
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
end

struct CloseFailedRPC
    processid::String
    msgtype::String
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
            require_ssl_verification=false)
        body = String(r.body)
        rpcreplymsg = unmarshaljson2dict(body)
        payload = String(base64decode(rpcreplymsg["payload"]))
        return payload, rpcreplymsg["payloadtype"]
    catch err
        if isa(err, HTTP.ConnectError)
            @error err
            Base.error(err)
        else
            rpcreplymsg = unmarshaljson2dict(String(err.response.body))
            payload = String(base64decode(rpcreplymsg["payload"]))
            failure_msg = unmarshaljson2dict(payload)
            @error failure_msg["message"]
            Base.error(failure_msg["message"])
        end
    end
end
