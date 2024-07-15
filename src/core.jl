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
	desc::String
end

Base.@kwdef struct GPU 
	name::String = ""
	mem::String = ""
	count::Int64 = 0
	nodecount::Int64 = 0
end

Base.@kwdef struct Hardware 
    model::String
	nodes::Int64
	cpu::String
	mem::String
	storage::String
	gpu::GPU
end

Base.@kwdef struct Software
	name::String
	type::String
	version::String
end

Base.@kwdef struct Capabilities 
    hardware::Hardware
    software::Software
end

Base.@kwdef struct Project
    allocatedcpu::Int64
	usedcpu::Int64
	allocagtedgpu::Int64
	usedgpu::Int64
	allocatedstorage::Int64
	usedstorage::Int64
end

Base.@kwdef struct Allocations
	projects::Dict{String, Project}
end

Base.@kwdef struct Executor
    executorid::String
    executortype::String
    executorname::String
    colonyname::String
    state::Int64
    requirefuncreg::Bool
    commissiontime::String
    lastheardfromtime::String
    location::Location
	capabilities::Capabilities
	allocations::Allocations

    function Executor(executorid::String, executortype::String, executorname::String, colonyname::String)
        new(executorid, executortype, executorname, colonyname, Colonies.PENDING, false, "2022-08-08T10:22:25.819199495+02:00", "2022-08-08T10:22:25.819199495+02:00", Location(0.0, 0.0, ""), Capabilities(Hardware("", 0, "  ", "", "", GPU("", "", 0, 0)), Software("", "", "")), Allocations(Dict{String, Project}()))
    end

    function Executor(executorid::String, executortype::String, executorname::String, colonyname::String, state::Int64, requirefuncreg::Bool, commissiontime::String, lastheardfromtime::String, location::Location, capabilities::Capabilities, allocations::Allocations)
        new(executorid, executortype, executorname, colonyname, state, requirefuncreg, commissiontime, lastheardfromtime, location, capabilities, allocations)
    end
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

	#  func = Colonies.Function(executor.executorid, colonyname, "testfunc", "tes  tdesc", [])
	#
	function Function(executorname::String, colonyname::String, funcname::String) 
		new("", executorname, "", colonyname, funcname, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	end


    # function Function(executorid, colonyid, funcname, desc, args)
    #     new("", Ixecutorid, colonyid, funcname, desc, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, args)
    # end
    #
    # function Function(functionid, executorid, colonyid, funcname, desc, counter, minwaittime, maxwaittime, minexectime, maxexectime, avgwaittime, avgexectime, args)
    #     new(functionid, executorid, colonyid, funcname, desc, counter, minwaittime, maxwaittime, minexectime, maxexectime, avgwaittime, avgexectime, args)
    # end
end


@kwdef struct Conditions
    colonyname::String
    executornames::Union{Array{String, 1}, Nothing}
    executortype::String
    dependencies::Union{Array{String, 1}, Nothing} = []
    nodes::Int64 = 0
    cpu::String = ""
    processes::Int64 = 0
    processespernode::Int64 = 0
    mem::String = ""
    storage::String = ""
    gpu::GPU = Union{GPU, Nothing}
    walltime::Int64 = ""

    function Conditions(
        colonyname::String,
        executornames::Union{Array{String, 1}, Nothing},
        executortype::String,
        dependencies::Union{Array{String, 1}, Nothing} = []
    )
	new(colonyname, executornames, executortype, dependencies, 0, "", 0, 0, "", "", GPU("", "", 0, 0), 0)
    end

    function Conditions(
        colonyname::String,
        executornames::Union{Array{String, 1}, Nothing},
        executortype::String,
        dependencies::Union{Array{String, 1}, Nothing},
        nodes::Int64,
        cpu::String,
        processes::Int64,
        processes_per_node::Int64,
        mem::String,
        storage::String,
        gpu::GPU,
        walltime::Int64
    )
        new(colonyname, executornames, executortype, dependencies, nodes, cpu, processes, processes_per_node, mem, storage, gpu, walltime)
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

@kwdef struct FunctionSpec
    nodename::String
    funcname::String
    args::Union{Array{Any, 1}, Nothing} = []
    kwargs::Dict{String, Any} = Dict{String, Any}()
    priority::Int64
    maxwaittime::Int64
    maxexectime::Int64
    maxretries::Int64
    conditions::Conditions
    label::String
    fs::Filesystem = Filesystem()
    env::Dict{String, String} = Dict{String, String}()

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
		env::Dict{Any, Any}
	)
		new(nodename, funcname, args, kwargs, priority, maxwaittime, maxexectime, maxretries, conditions, label, fs, env)
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
            Dict{String, String}(k => string(v) for (k, v) in env)
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
			Dict{String, String}())
        
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
		new("", targetid, targetcolonyname, "", OUT, 0, key, value)
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
