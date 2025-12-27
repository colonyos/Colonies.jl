# Colonies.jl API Reference

This document provides a comprehensive reference for all functions available in the Colonies.jl SDK.

## Table of Contents

- [Client](#client)
- [Colony Management](#colony-management)
- [Executor Management](#executor-management)
- [Process Management](#process-management)
- [Workflow Management](#workflow-management)
- [Functions](#functions)
- [Logs](#logs)
- [Channels](#channels)
- [Blueprints](#blueprints)
- [Statistics](#statistics)
- [Core Types](#core-types)

---

## Client

### `client()`

Creates a client from environment variables.

```julia
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()
```

**Environment Variables:**
- `COLONIES_SERVER_HOST` - Server hostname
- `COLONIES_SERVER_PORT` - Server port
- `COLONIES_SERVER_TLS` - "true" for HTTPS, "false" for HTTP
- `COLONIES_COLONY_NAME` - Colony name
- `COLONIES_COLONY_PRVKEY` - Colony private key
- `COLONIES_EXECUTOR_NAME` - Executor name
- `COLONIES_PRVKEY` - Executor private key

**Returns:** Tuple of (ColoniesClient, colonyname, colony_prvkey, executorname, prvkey)

### `ColoniesClient`

```julia
struct ColoniesClient
    protocol::String  # "http" or "https"
    host::String
    port::Int64
end
```

---

## Colony Management

### `addcolony(client, colony, prvkey)`

Adds a new colony (requires server owner key).

```julia
colony = Colonies.Colony(colonyid="...", name="mycolony")
result = Colonies.addcolony(client, colony, server_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colony::Colony` - Colony to add
- `prvkey::String` - Server owner private key

**Returns:** `Colony`

### `getcolony(client, colonyname, prvkey)`

Gets colony information.

```julia
colony = Colonies.getcolony(client, "mycolony", prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Name of the colony
- `prvkey::String` - Executor private key

**Returns:** `Colony`

### `getcolonies(client, prvkey)`

Gets all colonies (requires server owner key).

```julia
colonies = Colonies.getcolonies(client, server_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `prvkey::String` - Server owner private key

**Returns:** `Vector{Colony}`

### `removecolony(client, colonyname, prvkey)`

Removes a colony (requires server owner key).

```julia
Colonies.removecolony(client, "mycolony", server_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Name of the colony to remove
- `prvkey::String` - Server owner private key

**Returns:** `nothing`

---

## Executor Management

### `addexecutor(client, executor, prvkey)`

Adds a new executor (requires colony owner key).

```julia
executor_prvkey = Crypto.prvkey()
executor = Colonies.Executor(
    Crypto.id(executor_prvkey),
    "my-executor-type",
    "my-executor-name",
    colonyname
)
result = Colonies.addexecutor(client, executor, colony_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `executor::Executor` - Executor to add
- `prvkey::String` - Colony owner private key

**Returns:** `Executor`

### `approveexecutor(client, colonyname, executorname, prvkey)`

Approves an executor (requires colony owner key).

```julia
Colonies.approveexecutor(client, colonyname, "my-executor", colony_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `executorname::String` - Name of executor to approve
- `prvkey::String` - Colony owner private key

**Returns:** `nothing`

### `rejectexecutor(client, colonyname, executorname, prvkey)`

Rejects an executor (requires colony owner key).

```julia
Colonies.rejectexecutor(client, colonyname, "my-executor", colony_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `executorname::String` - Name of executor to reject
- `prvkey::String` - Colony owner private key

**Returns:** `nothing`

### `getexecutor(client, colonyname, executorname, prvkey)`

Gets executor information.

```julia
executor = Colonies.getexecutor(client, colonyname, "my-executor", prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `executorname::String` - Executor name
- `prvkey::String` - Executor private key

**Returns:** `Executor`

### `getexecutors(client, colonyname, prvkey)`

Gets all executors in a colony.

```julia
executors = Colonies.getexecutors(client, colonyname, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `prvkey::String` - Executor private key

**Returns:** `Vector{Executor}`

### `removeexecutor(client, colonyname, executorname, prvkey)`

Removes an executor (requires colony owner key).

```julia
Colonies.removeexecutor(client, colonyname, "my-executor", colony_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `executorname::String` - Executor name to remove
- `prvkey::String` - Colony owner private key

**Returns:** `nothing`

### `addfunction(client, func, prvkey)`

Registers a function for an executor.

```julia
func = Colonies.Function("my-executor", colonyname, "myfunction")
Colonies.addfunction(client, func, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `func::Function` - Function to register
- `prvkey::String` - Executor private key

**Returns:** `Function`

---

## Process Management

### `submit(client, spec, prvkey)`

Submits a function specification as a process.

```julia
conditions = Colonies.Conditions(
    colonyname=colonyname,
    executortype="my-executor-type"
)
spec = Colonies.FunctionSpec(
    funcname="myfunction",
    args=["arg1", "arg2"],
    maxexectime=60,
    conditions=conditions
)
process = Colonies.submit(client, spec, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `spec::FunctionSpec` - Function specification
- `prvkey::String` - Executor private key

**Returns:** `ProcessResult`

### `assign(client, colonyname, timeout, prvkey)`

Assigns a waiting process to the executor.

```julia
process = Colonies.assign(client, colonyname, 10, executor_prvkey)
if process !== nothing
    # Process assigned
end
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `timeout::Int64` - Timeout in seconds (blocks until process available or timeout)
- `prvkey::String` - Executor private key

**Returns:** `ProcessResult` or `nothing` if timeout

### `getprocess(client, processid, prvkey)`

Gets a process by ID.

```julia
process = Colonies.getprocess(client, processid, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `prvkey::String` - Executor private key

**Returns:** `ProcessResult`

### `getprocesses(client, colonyname, state, count, prvkey)`

Gets processes by state.

```julia
# Get waiting processes
waiting = Colonies.getprocesses(client, colonyname, Colonies.WAITING, 100, prvkey)

# Get running processes
running = Colonies.getprocesses(client, colonyname, Colonies.RUNNING, 100, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `state::Int64` - Process state (WAITING=0, RUNNING=1, SUCCESS=2, FAILED=3)
- `count::Int64` - Maximum number of processes to return
- `prvkey::String` - Executor private key

**Returns:** `Vector{ProcessResult}`

### `closeprocess(client, processid, prvkey, out)`

Closes a process as successful.

```julia
Colonies.closeprocess(client, processid, executor_prvkey, ["result1", "result2"])
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `prvkey::String` - Executor private key (must be assigned executor)
- `out::Vector{String}` - Output values (optional, defaults to empty)

**Returns:** `nothing`

### `failprocess(client, processid, prvkey, errors)`

Closes a process as failed.

```julia
Colonies.failprocess(client, processid, executor_prvkey, ["Error message"])
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `prvkey::String` - Executor private key (must be assigned executor)
- `errors::Vector{String}` - Error messages (optional, defaults to empty)

**Returns:** `nothing`

### `setoutput(client, processid, output, prvkey)`

Sets output values for a running process.

```julia
Colonies.setoutput(client, processid, ["value1", "value2"], executor_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `output::Vector` - Output values
- `prvkey::String` - Executor private key

**Returns:** `nothing`

### `addattribute(client, attribute, prvkey)`

Adds an attribute to a process.

```julia
attr = Colonies.Attribute(processid, colonyname, "key", "value")
Colonies.addattribute(client, attr, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `attribute::Attribute` - Attribute to add
- `prvkey::String` - Executor private key

**Returns:** `Attribute`

### `addchild(client, processgraphid, processid, spec, prvkey)`

Adds a child process to a workflow.

```julia
child = Colonies.addchild(client, graphid, parentid, childspec, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processgraphid::String` - Workflow ID
- `processid::String` - Parent process ID
- `spec::FunctionSpec` - Child function specification
- `prvkey::String` - Executor private key

**Returns:** `ProcessResult`

### `removeprocess(client, processid, prvkey)`

Removes a process.

```julia
Colonies.removeprocess(client, processid, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID to remove
- `prvkey::String` - Executor private key

**Returns:** `nothing`

### `removeallprocesses(client, colonyname, prvkey; state)`

Removes all processes (requires colony owner key).

```julia
# Remove all processes
Colonies.removeallprocesses(client, colonyname, colony_prvkey)

# Remove only failed processes
Colonies.removeallprocesses(client, colonyname, colony_prvkey, state=Colonies.FAILED)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `prvkey::String` - Colony owner private key
- `state::Int64` - Optional, filter by state (-1 for all)

**Returns:** `nothing`

### `wait(client, process, timeout, prvkey)`

Waits for a process to complete (WebSocket subscription).

```julia
Colonies.wait(client, process, 60, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `process::Process` - Process to wait for
- `timeout::Int64` - Timeout in seconds
- `prvkey::String` - Executor private key

**Returns:** WebSocket response

---

## Workflow Management

### `submitworkflow(client, colonyname, functionspecs, prvkey)`

Submits a workflow (DAG of processes).

```julia
spec1 = Colonies.FunctionSpec(nodename="task1", funcname="func1", conditions=cond)
spec2 = Colonies.FunctionSpec(nodename="task2", funcname="func2", conditions=cond)
# spec2 depends on spec1 via conditions.dependencies

graph = Colonies.submitworkflow(client, colonyname, [spec1, spec2], prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `functionspecs::Vector{FunctionSpec}` - Array of function specifications
- `prvkey::String` - Executor private key

**Returns:** `ProcessGraph`

### `getprocessgraph(client, processgraphid, prvkey)`

Gets a workflow by ID.

```julia
graph = Colonies.getprocessgraph(client, graphid, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processgraphid::String` - Workflow ID
- `prvkey::String` - Executor private key

**Returns:** `ProcessGraph`

### `getprocessgraphs(client, colonyname, count, prvkey; state)`

Gets workflows.

```julia
# Get all workflows
graphs = Colonies.getprocessgraphs(client, colonyname, 100, prvkey)

# Get only running workflows
graphs = Colonies.getprocessgraphs(client, colonyname, 100, prvkey, state=Colonies.RUNNING)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `count::Int64` - Maximum number to return
- `prvkey::String` - Executor private key
- `state::Int64` - Optional, filter by state (-1 for all)

**Returns:** `Vector{ProcessGraph}`

### `removeprocessgraph(client, processgraphid, prvkey)`

Removes a workflow.

```julia
Colonies.removeprocessgraph(client, graphid, prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processgraphid::String` - Workflow ID
- `prvkey::String` - Executor private key

**Returns:** `nothing`

### `removeallprocessgraphs(client, colonyname, prvkey; state)`

Removes all workflows (requires colony owner key).

```julia
Colonies.removeallprocessgraphs(client, colonyname, colony_prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `prvkey::String` - Colony owner private key
- `state::Int64` - Optional, filter by state (-1 for all)

**Returns:** `nothing`

---

## Functions

### `getfunctions(client, colonyname, prvkey)`

Gets all registered functions.

```julia
functions = Colonies.getfunctions(client, colonyname, prvkey)
for f in functions
    println(f.funcname, " -> ", f.executortype)
end
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `prvkey::String` - Executor private key

**Returns:** `Vector{Function}`

---

## Logs

### `addlog(client, processid, msg, prvkey)`

Adds a log message to a process.

```julia
Colonies.addlog(client, processid, "Processing step 1 complete\n", prvkey)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `msg::String` - Log message
- `prvkey::String` - Executor private key

**Returns:** `nothing`

### `getlogs(client, colonyname, processid, count, since, prvkey)`

Gets logs for a process.

```julia
logs = Colonies.getlogs(client, colonyname, processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `processid::String` - Process ID
- `count::Int` - Maximum number of log entries
- `since::Int64` - Timestamp to get logs after (0 for all)
- `prvkey::String` - Executor private key

**Returns:** `Vector{Log}`

---

## Channels

Channels provide real-time messaging between processes.

### `channelappend(client, processid, channel_name, sequence, data, prvkey; msgtype, inreplyto)`

Appends a message to a channel.

```julia
# Simple data message
Colonies.channelappend(client, processid, "output", 1, "Hello", prvkey)

# Message with type and reply reference
Colonies.channelappend(client, processid, "output", 2, "Done", prvkey,
                       msgtype="end", inreplyto=1)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `channel_name::String` - Channel name
- `sequence::Int64` - Sequence number
- `data::String` - Message data
- `prvkey::String` - Executor private key
- `msgtype::String` - Message type: "data", "end", or "error" (default: "data")
- `inreplyto::Int64` - Sequence number this replies to (default: 0)

**Returns:** `nothing`

### `channelread(client, processid, channel_name, after_seq, limit, prvkey)`

Reads messages from a channel.

```julia
entries = Colonies.channelread(client, processid, "output", 0, 100, prvkey)
for entry in entries
    println("Seq $(entry.sequence): $(entry.data)")
end
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `processid::String` - Process ID
- `channel_name::String` - Channel name
- `after_seq::Int64` - Get messages after this sequence number
- `limit::Int64` - Maximum number of messages
- `prvkey::String` - Executor private key

**Returns:** `Vector{ChannelEntry}`

---

## Blueprints

Blueprints define declarative resource specifications that reconcilers manage.

### Blueprint Definitions

#### `addblueprintdefinition(client, definition, prvkey)`

Adds a blueprint definition.

```julia
def = Colonies.BlueprintDefinition(
    name="MyResource",
    colonyname=colonyname,
    kind="MyResource",
    executortype="my-reconciler",
    specschema=Dict{String, Any}(),
    statusschema=Dict{String, Any}()
)
result = Colonies.addblueprintdefinition(client, def, prvkey)
```

**Returns:** `BlueprintDefinition`

#### `getblueprintdefinition(client, colonyname, name, prvkey)`

Gets a blueprint definition.

```julia
def = Colonies.getblueprintdefinition(client, colonyname, "MyResource", prvkey)
```

**Returns:** `BlueprintDefinition`

#### `getblueprintdefinitions(client, colonyname, prvkey)`

Gets all blueprint definitions.

```julia
defs = Colonies.getblueprintdefinitions(client, colonyname, prvkey)
```

**Returns:** `Vector{BlueprintDefinition}`

#### `removeblueprintdefinition(client, colonyname, name, prvkey)`

Removes a blueprint definition.

```julia
Colonies.removeblueprintdefinition(client, colonyname, "MyResource", prvkey)
```

**Returns:** `nothing`

### Blueprint Instances

#### `addblueprint(client, blueprint, prvkey)`

Adds a blueprint instance.

```julia
bp = Colonies.Blueprint(
    kind="MyResource",
    metadata=Colonies.BlueprintMetadata(name="my-resource", colonyname=colonyname),
    handler=Colonies.BlueprintHandler(executortype="my-reconciler"),
    spec=Dict{String, Any}("key" => "value"),
    status=Dict{String, Any}()
)
result = Colonies.addblueprint(client, bp, prvkey)
```

**Returns:** `Blueprint`

#### `getblueprint(client, colonyname, name, prvkey)`

Gets a blueprint by name.

```julia
bp = Colonies.getblueprint(client, colonyname, "my-resource", prvkey)
```

**Returns:** `Blueprint`

#### `getblueprints(client, colonyname, prvkey; kind, location)`

Gets blueprints with optional filtering.

```julia
# Get all blueprints
bps = Colonies.getblueprints(client, colonyname, prvkey)

# Filter by kind
bps = Colonies.getblueprints(client, colonyname, prvkey, kind="MyResource")
```

**Returns:** `Vector{Blueprint}`

#### `updateblueprint(client, blueprint, prvkey; forcegeneration)`

Updates a blueprint.

```julia
bp.spec["key"] = "new-value"
updated = Colonies.updateblueprint(client, bp, prvkey)

# Force generation increment
updated = Colonies.updateblueprint(client, bp, prvkey, forcegeneration=true)
```

**Returns:** `Blueprint`

#### `removeblueprint(client, colonyname, name, prvkey)`

Removes a blueprint.

```julia
Colonies.removeblueprint(client, colonyname, "my-resource", prvkey)
```

**Returns:** `nothing`

#### `updateblueprintstatus(client, colonyname, name, status, prvkey)`

Updates only the status of a blueprint.

```julia
status = Dict{String, Any}("state" => "ready", "message" => "Resource created")
Colonies.updateblueprintstatus(client, colonyname, "my-resource", status, prvkey)
```

**Returns:** `nothing`

#### `reconcileblueprint(client, colonyname, name, prvkey; force)`

Triggers reconciliation of a blueprint.

```julia
# Normal reconciliation
process = Colonies.reconcileblueprint(client, colonyname, "my-resource", prvkey)

# Force reconciliation
process = Colonies.reconcileblueprint(client, colonyname, "my-resource", prvkey, force=true)
```

**Returns:** `ProcessResult`

---

## Statistics

### `getstats(client, colonyname, prvkey)`

Gets colony statistics.

```julia
stats = Colonies.getstats(client, colonyname, prvkey)
println("Waiting: ", stats.waitingprocesses)
println("Running: ", stats.runningprocesses)
println("Success: ", stats.successfulprocesses)
println("Failed: ", stats.failedprocesses)
```

**Parameters:**
- `client::ColoniesClient` - The client instance
- `colonyname::String` - Colony name
- `prvkey::String` - Executor private key

**Returns:** `Statistics`

---

## Core Types

### Process States

```julia
const WAITING = 0
const RUNNING = 1
const SUCCESS = 2
const FAILED = 3
```

### Attribute Types

```julia
const IN_TYPE = 0
const OUT_TYPE = 1
const ERR_TYPE = 2
const ENV_TYPE = 4
```

### Executor States

```julia
const PENDING = 0
const APPROVED = 1
const REJECTED = 2
```

### `Colony`

```julia
struct Colony
    colonyid::String
    name::String
end
```

### `Executor`

```julia
struct Executor
    executorid::String
    executortype::String
    executorname::String
    colonyname::String
    state::Int64
    requirefuncreg::Bool
    commissiontime::String
    lastheardfromtime::String
    locationname::String
    capabilities::Capabilities
    allocations::Allocations
end
```

### `FunctionSpec`

```julia
struct FunctionSpec
    nodename::String
    funcname::String
    args::Union{Array{Any, 1}, Nothing}
    kwargs::Dict{String, Any}
    priority::Int64
    maxwaittime::Int64
    maxexectime::Int64
    maxretries::Int64
    conditions::Conditions
    label::String
    fs::Filesystem
    env::Dict{String, String}
end
```

### `Conditions`

```julia
struct Conditions
    colonyname::String
    executornames::Union{Array{String, 1}, Nothing}
    executortype::String
    dependencies::Union{Array{String, 1}, Nothing}
    nodes::Int64
    cpu::String
    processes::Int64
    processespernode::Int64
    mem::String
    storage::String
    gpu::GPU
    walltime::Int64
end
```

### `ProcessResult`

```julia
mutable struct ProcessResult
    processid::String
    state::Int
    spec::Dict{String, Any}
    output::Vector{Any}
    errors::Vector{Any}
end
```

### `ProcessGraph`

```julia
struct ProcessGraph
    processgraphid::String
    colonyname::String
    state::Int64
    rootprocessids::Vector{String}
    processids::Vector{String}
end
```

### `Log`

```julia
struct Log
    processid::String
    colonyname::String
    executorname::String
    message::String
    timestamp::Int64
end
```

### `ChannelEntry`

```julia
struct ChannelEntry
    sequence::Int64
    data::String
    msgtype::String
    inreplyto::Int64
end
```

### `Statistics`

```julia
struct Statistics
    colonies::Int64
    executors::Int64
    waitingprocesses::Int64
    runningprocesses::Int64
    successfulprocesses::Int64
    failedprocesses::Int64
    waitingworkflows::Int64
    runningworkflows::Int64
    successfulworkflows::Int64
    failedworkflows::Int64
end
```

### `Blueprint`

```julia
struct Blueprint
    blueprintid::String
    kind::String
    metadata::BlueprintMetadata
    handler::BlueprintHandler
    spec::Dict{String, Any}
    status::Dict{String, Any}
    generation::Int64
    reconciledgeneration::Int64
    lastreconciled::String
end
```

### `BlueprintDefinition`

```julia
struct BlueprintDefinition
    name::String
    colonyname::String
    kind::String
    executortype::String
    specschema::Dict{String, Any}
    statusschema::Dict{String, Any}
end
```
