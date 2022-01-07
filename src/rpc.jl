include("./core.jl")
include("./Crypto.jl")

import .Crypto

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

struct AssignProcessRPC
  colonyid::String
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

function sendrpcmsg(rpcmsg::RPCMsg)
  url = "https://localhost:8080/api"
  body = ""
  try
    r = HTTP.request("POST", url,
                    ["Content-Type" => "plain/text"],
                    JSON2.write(rpcmsg),
                    require_ssl_verification=false)
    body = String(r.body)
    rpcreplymsg = JSON.parse(body)
    payload = String(base64decode(rpcreplymsg["payload"]))
    return payload, rpcreplymsg["payloadtype"]
  catch err
    rpcreplymsg = JSON.parse(String(err.response.body))
    payload = String(base64decode(rpcreplymsg["payload"]))
    failure_msg = JSON.parse(payload)
    Base.error(failure_msg["message"])
  end
end
