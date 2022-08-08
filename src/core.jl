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

Base.@kwdef struct Colony
    colonyid::String
    name::String
end

Base.@kwdef struct Runtime
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
    commissiontime::String
    lastheardfromtime::String

    function Runtime(runtimeid::String, runtimetype::String, name::String, colonyid::String, cpu::String, cores::Int64, mem::Int64, gpu::String, gpus::Int64, state::Int64)
        new(runtimeid, runtimetype, name, colonyid, cpu, cores, mem, gpu, gpus, state, "2022-08-08T10:22:25.819199495+02:00", "2022-08-08T10:22:25.819199495+02:00")
    end

    function Runtime(runtimeid::String, runtimetype::String, name::String, colonyid::String, cpu::String, cores::Int64, mem::Int64, gpu::String, gpus::Int64, state::Int64, commissiontime::String, lastheardfromtime::String)
        new(runtimeid, runtimetype, name, colonyid, cpu, cores, mem, gpu, gpus, state, commissiontime, lastheardfromtime)
    end
end

Base.@kwdef struct Conditions
    colonyid::String
    runtimeids::Union{Array{String,1},Nothing}
    runtimetype::String
    dependencies::Union{Array{String,1},Nothing} = []
end

Base.@kwdef struct ProcessSpec
    name::String
    func::String
    args::Union{Array{String,1},Nothing} = []
    priority::Int16
    maxwaittime::Int16
    maxexectime::Int16
    maxretries::Int16
    conditions::Conditions
    env::Dict{String,String}

    function ProcessSpec(name, func, args, priority, maxwaittime, maxexectime, maxretries, conditions, env)
        new(name, func, args, priority, maxwaittime, maxexectime, maxretries, conditions, env)
    end
end

Base.@kwdef struct Attribute
    attributeid::String
    targetid::String
    targetcolonyid::String
    targetprocessgraphid::String
    attributetype::UInt16
    key::String
    value::String

    function Attribute(targetid::String, targetcolonyid::String, key::String, value::String)
        new("", targetid, targetcolonyid, "", OUT, key, value)
    end

    function Attribute(attributeid::String, targetid::String, targetcolonyid::String, targetprocessgraphid::String, attributetype::UInt16, key::String, value::String)
        new(attributeid, targetid, targetcolonyid, targetprocessgraphid, attributetype, key, value)
    end
end

Base.@kwdef struct Process
    processid::String
    assignedruntimeid::String
    isassigned::Bool
    state::UInt16
    submissiontime::String
    starttime::String
    endtime::String
    waitdeadline::String
    execdeadline::String
    errormsg::String
    retries::UInt16
    attributes::Union{Array{Attribute,1},Nothing} = []
    spec::ProcessSpec
    waitforparents::Bool
    parents::Union{Array{String,1},Nothing} = []
    children::Union{Array{String,1},Nothing} = []
    processgraphid::String = ""
end

function get_attr_value(process::Process, key::String)
    for attr in process.attributes
        if attr.key == key
            return attr.value
        end
    end
    return ""
end
