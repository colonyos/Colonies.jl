const PENDING = 0
const APPROVED = 1
const REJECTED = 2

const IN = 0
const OUT = 1
const ERR = 2
const ENV = 4

const WAITING = 0
const RUNNING = 1
const SUCCESS = 2
const FAILED = 3

struct Colony
  colonyid::String
  name::String
end

struct Runtime
  runtimeid::String
  runtimetype::String
  name::String
  colonyid::String
  cpu::String
  cores::Int64
  mem::Int64
  gpu::String
  gpus::Int64
  state::Int64

  function Runtime(runtimeid::String, runtimetype::String, name::String, colonyid::String, cpu::String, cores::Int64, mem::Int64, gpu::String,  gpus::Int64, state::Int64) 
    new(runtimeid, runtimetype, name, colonyid, cpu, cores, mem, gpu, gpus, state) 
  end

  function Runtime(runtimeid::String, runtimetype::String, name::String, colonyid::String, cpu::String, cores::Int64, mem::Int64, gpu::String,  gpus::Int64) 
    new(runtimeid, runtimetype, name, colonyid, cpu, cores, mem, gpu, gpus, PENDING) 
  end

  function Runtime(runtimeid::String, runtimetype::String, name::String, colonyid::String) 
    new(runtimeid, runtimetype, name, colonyid, "", 1, 0, "", 0, PENDING) 
  end

end

struct Conditions
  colonyid::String
  runtimeids::Array{String,1}
  runtimetype::String
  mem::UInt16
  cores::UInt16
  gpus::UInt16
end

struct ProcessSpec 
  timeout::Int16
  maxretries::Int16
  conditions::Conditions
  env::Dict{String,String}
end

struct Attribute 
  attributeid::String
  targetid::String
  attributetype::UInt16
  key::String
  value::String

  function Attribute(targetid::String, key::String, value::String) 
    new("", targetid, OUT, key, value)
  end
  
  function Attribute(attributeid::String, targetid::String,attributetype::UInt16, key::String, value::String) 
    new(attributeid, targetid, attributetype, key, value)
  end
end

struct Process
  processid::String
  assignedruntimeid::String
  isassigned::Bool
  state::UInt16
  submissiontime::String
  starttime::String
  endtime::String
  deadline::String
  retries::UInt16
  attributes::Array{Attribute,1}
  spec::ProcessSpec
end
