const PENDING = 0
const APPROVED = 1
const REJECTED = 2

const IN_TYPE = 0
const OUT_TYPE = 1
const ERR_TYPE = 2
const ENV_TYPE = 4

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
	desc::String
end

Base.@kwdef struct GPU
	name::String = ""
	mem::String = ""
	count::Int64 = 0
	nodecount::Int64 = 0

	function GPU(name::String, mem::String, count::Int64, nodecount::Int64)
		new(name, mem, count, nodecount)
	end

	function GPU(name::String, mem::String, count::Int64)
		new(name, mem, count, 0)
	end
end

Base.@kwdef struct Hardware
    model::String = ""
	nodes::Int64 = 0
	cpu::String = ""
	mem::String = ""
	storage::String = ""
	gpu::GPU = GPU()
end

Base.@kwdef struct Software
	name::String = ""
	swtype::String = ""
	version::String = ""
end

# Capabilities uses arrays to match Go server format
Base.@kwdef struct Capabilities
    hardware::Vector{Hardware} = Hardware[]
    software::Vector{Software} = Software[]
end

Base.@kwdef struct Project
    allocatedcpu::Int64 = 0
	usedcpu::Int64 = 0
	allocatedgpu::Int64 = 0
	usedgpu::Int64 = 0
	allocatedstorage::Int64 = 0
	usedstorage::Int64 = 0
end

Base.@kwdef struct Allocations
	projects::Dict{String, Project} = Dict{String, Project}()
end

Base.@kwdef struct Executor
    executorid::String
    executortype::String
    executorname::String
    colonyname::String
    state::Int64 = PENDING
    requirefuncreg::Bool = false
    commissiontime::String = ""
    lastheardfromtime::String = ""
    locationname::String = ""
	capabilities::Capabilities = Capabilities()
	allocations::Allocations = Allocations()

    function Executor(executorid::String, executortype::String, executorname::String, colonyname::String)
        new(executorid, executortype, executorname, colonyname, PENDING, false, "", "", "", Capabilities(), Allocations())
    end

    function Executor(executorid::String, executortype::String, executorname::String, colonyname::String, state::Int64, requirefuncreg::Bool, commissiontime::String, lastheardfromtime::String, locationname::String, capabilities::Capabilities, allocations::Allocations)
        new(executorid, executortype, executorname, colonyname, state, requirefuncreg, commissiontime, lastheardfromtime, locationname, capabilities, allocations)
    end
end

# Simple process result that uses Dict for spec to avoid complex nested struct parsing
Base.@kwdef mutable struct ProcessResult
    processid::String = ""
    state::Int = 0
    spec::Dict{String, Any} = Dict{String, Any}()
    output::Vector{Any} = []
    errors::Vector{Any} = []
end

Base.@kwdef struct Function
    functionid::String
    executorname::String
    executortype::String
    colonyname::String
    funcname::String
    counter::Int64
    minwaittime::Float64
    maxwaittime::Float64
    minexectime::Float64
    maxexectime::Float64
    avgwaittime::Float64
    avgexectime::Float64

	function Function(functionid::String, executorname::String, executortype::String, colonyname::String, funcname::String, counter::Int64, minwaittime::Float64, maxwaittime::Float64, minexectime::Float64, maxexectime::Float64, avgwaittime::Float64, avgexectime::Float64)
		new(functionid, executorname, executortype, colonyname, funcname, counter, minwaittime, maxwaittime, minexectime, maxexectime, avgwaittime, avgexectime)
	end

	function Function(executorname::String, colonyname::String, funcname::String) 
		new("", executorname, "", colonyname, funcname, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	end
end

@kwdef struct Conditions
    colonyname::String = ""
    executornames::Union{Array{String, 1}, Nothing} = String[]
    executortype::String = ""
    locationname::String = ""
    dependencies::Union{Array{String, 1}, Nothing} = String[]
    nodes::Int64 = 1
    cpu::String = "1000m"
    processes::Int64 = 0
    processespernode::Int64 = 1
    mem::String = "0Gi"
    storage::String = "0Gi"
	gpu::GPU = GPU("", "", 0, 0)
    walltime::Int64 = 60

    function Conditions(
        colonyname::String,
        executornames::Union{Array{String, 1}, Nothing},
        executortype::String,
        dependencies::Union{Array{String, 1}, Nothing} = []
    )
	new(colonyname, executornames, executortype, "", dependencies, 1, "", 1, 1, "", "", GPU("", "", 0, 0), 0)
    end

    function Conditions(
        colonyname::String,
        executornames::Union{Array{String, 1}, Nothing},
        executortype::String,
        locationname::String,
        dependencies::Union{Array{String, 1}, Nothing},
        nodes::Int64,
        cpu::String,
        processes::Int64,
        processespernode::Int64,
        mem::String,
        storage::String,
        gpu::GPU,
        walltime::Int64
    )
        new(colonyname, executornames, executortype, locationname, dependencies, nodes, cpu, processes, processespernode, mem, storage, gpu, walltime)
    end
end

Base.@kwdef struct SnapshotMount
	snapshotid::String
	label::String
	dir::String
	keepfiles::Bool
	keepsnapshots::Bool
end

Base.@kwdef struct OnStart
	keeplocal::Bool
end

Base.@kwdef struct OnClose
	keeplocal::Bool
end

Base.@kwdef struct ConnflictResolution
	onstart::OnStart
	onclose::OnClose
end

Base.@kwdef struct SyncDirMount
	label::String
	dir::String
	keepfiles::Bool
	onconflicts::ConnflictResolution
end

Base.@kwdef struct Filesystem
	mount::String = ""
    snapshots::Union{Array{SnapshotMount,1},Nothing} = []
    dirs::Union{Array{SyncDirMount,1},Nothing} = []
end

Base.@kwdef struct Log 
    processid::String
    colonyname::String
    executorname::String
    message::String
    timestamp::Int64
end

@kwdef struct FunctionSpec
    nodename::String = ""
    funcname::String = ""
    args::Union{Array{Any, 1}, Nothing} = []
    kwargs::Dict{String, Any} = Dict{Any, Any}()
    priority::Int64 = 0
    maxwaittime::Int64 = 0
    maxexectime::Int64 = 60
    maxretries::Int64 = 3
    conditions::Conditions
    label::String = ""
    fs::Filesystem = Filesystem()
    env::Dict{String, String} = Dict{Any, Any}()
    channels::Union{Array{String, 1}, Nothing} = String[]

	function FunctionSpec(
		nodename::String,
		funcname::String,
		args::Union{Array{Any, 1}, Nothing},
		kwargs::Dict{Any, Any},
		priority::Int64,
		maxwaittime::Int64,
		maxexectime::Int64,
		maxretries::Int64,
		conditions::Conditions,
		label::String,
		fs::Filesystem,
		env::Dict{Any, Any},
		channels::Union{Array{String, 1}, Nothing} = String[]
	)
		new(nodename, funcname, args, kwargs, priority, maxwaittime, maxexectime, maxretries, conditions, label, fs, env, channels)
	end

    function FunctionSpec(
        nodename::String,
        funcname::String,
        args::Union{Array{String, 1}, Nothing},
        priority::Int64,
        maxwaittime::Int64,
        maxexectime::Int64,
        maxretries::Int64,
        conditions::Conditions,
        label::String,
        env::Dict{String, String}
    )
        new(
            nodename,
            funcname,
            args,
            Dict{String, Any}(),
            priority,
            maxwaittime,
            maxexectime,
            maxretries,
            conditions,
            label,
            Filesystem(),
            Dict{String, String}(k => string(v) for (k, v) in env),
            String[]
        )
    end

	function FunctionSpec(
        nodename::String,
        funcname::String,
        args::Union{Array{String, 1}, Nothing},
        priority::Int64,
        maxwaittime::Int64,
        maxexectime::Int64,
        maxretries::Int64,
        conditions::Conditions,
        label::String
    )
        new(
            nodename,
            funcname,
            args,
            Dict{String, Any}(),
            priority,
            maxwaittime,
            maxexectime,
            maxretries,
            conditions,
            label,
            Filesystem(),
			Dict{String, String}(),
            String[]
        )
    end
end

Base.@kwdef struct Attribute
    attributeid::String
    targetid::String
    targetcolonyname::String
    targetprocessgraphid::String
    state::Int64
	attributetype::Int64
    key::String
    value::String

	function Attribute(attributeid::String, targetid::String, targetcolonyname::String, targetprocessgraphid::String, state::Int64, attributetype::Int64, key::String, value::String)
		new(attributeid, targetid, targetcolonyname, targetprocessgraphid, state, attributetype, key, value)
	end

	function Attribute(targetid::String, targetcolonyname::String, key::String, value::String)
		new("", targetid, targetcolonyname, "", OUT_TYPE, 0, key, value)
	end
end

Base.@kwdef struct Process
    processid::String
   	initiatorid::String
	initiatorname::String
	assignedexecutorid::String
    isassigned::Bool
    state::UInt16
    prioritytime::UInt64
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
    in::Union{Array{Any,1},Nothing} = []
    out::Union{Array{Any,1},Nothing} = []
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

# ProcessGraph represents a workflow DAG
Base.@kwdef struct ProcessGraph
    processgraphid::String = ""
    colonyname::String = ""
    state::Int64 = 0
    rootprocessids::Vector{String} = String[]
    processids::Vector{String} = String[]
end

# Statistics contains colony statistics
Base.@kwdef struct Statistics
    colonies::Int64 = 0
    executors::Int64 = 0
    waitingprocesses::Int64 = 0
    runningprocesses::Int64 = 0
    successfulprocesses::Int64 = 0
    failedprocesses::Int64 = 0
    waitingworkflows::Int64 = 0
    runningworkflows::Int64 = 0
    successfulworkflows::Int64 = 0
    failedworkflows::Int64 = 0
end

# ChannelEntry represents a message in a channel
Base.@kwdef struct ChannelEntry
    sequence::Int64 = 0
    data::String = ""
    msgtype::String = "data"
    inreplyto::Int64 = 0
end

# BlueprintDefinition defines a blueprint type
Base.@kwdef struct BlueprintDefinition
    name::String = ""
    colonyname::String = ""
    kind::String = ""
    executortype::String = ""
    specschema::Dict{String, Any} = Dict{String, Any}()
    statusschema::Dict{String, Any} = Dict{String, Any}()
end

# BlueprintHandler defines which executor handles the blueprint
Base.@kwdef struct BlueprintHandler
    executortype::String = ""
end

# BlueprintMetadata contains blueprint metadata
Base.@kwdef struct BlueprintMetadata
    name::String = ""
    colonyname::String = ""
end

# Blueprint represents a blueprint instance
Base.@kwdef struct Blueprint
    blueprintid::String = ""
    kind::String = ""
    metadata::BlueprintMetadata = BlueprintMetadata()
    handler::BlueprintHandler = BlueprintHandler()
    spec::Dict{String, Any} = Dict{String, Any}()
    status::Dict{String, Any} = Dict{String, Any}()
    generation::Int64 = 0
    reconciledgeneration::Int64 = 0
    lastreconciled::String = ""
end
