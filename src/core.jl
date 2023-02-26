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

Base.@kwdef struct Location
    long::Float64
    lat::Float64
end

Base.@kwdef struct Function
    functionid::String
    executorid::String
    colonyid::String
    funcname::String
    desc::String
    counter::Int64
    minwaittime::Float64
    maxwaittime::Float64
    minexectime::Float64
    maxexectime::Float64
    avgwaittime::Float64
    avgexectime::Float64
    args::Array{String,1}

    function Function(executorid, colonyid, funcname, desc, args)
        new("", executorid, colonyid, funcname, desc, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, args)
    end

    function Function(functionid, executorid, colonyid, funcname, desc, counter, minwaittime, maxwaittime, minexectime, maxexectime, avgwaittime, avgexectime, args)
        new(functionid, executorid, colonyid, funcname, desc, counter, minwaittime, maxwaittime, minexectime, maxexectime, avgwaittime, avgexectime, args)
    end
end

Base.@kwdef struct Executor
    executorid::String
    executortype::String
    executorname::String
    colonyid::String
    state::Int64
    requirefuncreg::Bool
    commissiontime::String
    lastheardfromtime::String
    location::Location

    function Executor(executorid::String, executortype::String, executorname::String, colonyid::String, state::Int64)
        new(executorid, executortype, executorname, colonyid, state, false, "2022-08-08T10:22:25.819199495+02:00", "2022-08-08T10:22:25.819199495+02:00", Colonies.Location(0.0, 0.0))
    end

    function Executor(executorid::String, executortype::String, executorname::String, colonyid::String, state::Int64, requirefuncreg::Bool, commissiontime::String, lastheardfromtime::String, location::Location)
        new(executorid, executortype, executorname, colonyid, state, requirefuncreg, commissiontime, lastheardfromtime, location)
    end
end

Base.@kwdef struct Conditions
    colonyid::String
    executorids::Union{Array{String,1},Nothing}
    executortype::String
    dependencies::Union{Array{String,1},Nothing} = []
end

Base.@kwdef struct FunctionSpec
    nodename::String
    funcname::String
    args::Union{Array{String,1},Nothing} = []
    priority::Int16
    prioritytime::Int16
    maxwaittime::Int16
    maxexectime::Int16
    maxretries::Int16
    conditions::Conditions
    label::String
    env::Dict{String,String}

    function FunctionSpec(name, funcname, args, priority, prioritytime, maxwaittime, maxexectime, maxretries, conditions, label, env)
        new(name, funcname, args, priority, prioritytime, maxwaittime, maxexectime, maxretries, conditions, label, env)
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
    assignedexecutorid::String
    isassigned::Bool
    state::UInt16
    submissiontime::String
    starttime::String
    endtime::String
    waitdeadline::String
    execdeadline::String
    retries::UInt16
    attributes::Union{Array{Attribute,1},Nothing} = []
    spec::FunctionSpec
    waitforparents::Bool
    parents::Union{Array{String,1},Nothing} = []
    children::Union{Array{String,1},Nothing} = []
    processgraphid::String = ""
    in::Union{Array{String,1},Nothing} = []
    out::Union{Array{String,1},Nothing} = []
    errors::Union{Array{String,1},Nothing} = []
end

function get_attr_value(process::Process, key::String)
    for attr in process.attributes
        if attr.key == key
            return attr.value
        end
    end
    return ""
end
