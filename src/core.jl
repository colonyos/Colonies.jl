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
    name::String
    args::Union{Array{String,1},Nothing}
end

Base.@kwdef struct Executor 
    executorid::String
    executortype::String
    executorname::String
    colonyid::String
    state::Int64
    commissiontime::String
    lastheardfromtime::String
    location::Location
    functions::Union{Array{Function,1},Nothing}

    function Executor(executorid::String, executortype::String, executorname::String, colonyid::String, state::Int64)
        new(executorid, executortype, executorname, colonyid, state, "2022-08-08T10:22:25.819199495+02:00", "2022-08-08T10:22:25.819199495+02:00", Colonies.Location(0.0, 0.0), [])
    end

    function Executor(executorid::String, executortype::String, executorname::String, colonyid::String, state::Int64, commissiontime::String, lastheardfromtime::String, location::Location, functions::Array{Function,1})
        new(executorid, executortype, executorname, colonyid, state, commissiontime, lastheardfromtime, location, functions)
    end
end

Base.@kwdef struct Conditions
    colonyid::String
    executorids::Union{Array{String,1},Nothing}
    executortype::String
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
    spec::ProcessSpec
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
