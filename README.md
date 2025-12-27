[![codecov](https://codecov.io/gh/colonyos/Colonies.jl/branch/main/graph/badge.svg?token=EJJ6X2ST2L)](https://codecov.io/gh/colonyos/Colonies.jl) [![Julia](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml/badge.svg)](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml)

# Colonies.jl

A Julia SDK for the [ColonyOS API](https://github.com/colonyos/colonies), enabling development of ColonyOS applications and executors in Julia.

## Documentation

- [Tutorial](docs/tutorial.md) - Getting started guide with step-by-step examples
- [API Reference](docs/api-reference.md) - Complete API documentation
- [ColonyOS Tutorials](https://github.com/colonyos/tutorials) - Advanced tutorials and examples

## Quick Start

### Installation

```julia
using Pkg
Pkg.add(url="https://github.com/colonyos/Colonies.jl")
```

### Setting Up the Development Environment

Start a local ColonyOS environment using Docker Compose:

```bash
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.env
source docker-compose.env
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.yml
docker-compose up -d
```

To stop and clean up:

```bash
docker-compose down --volumes
```

### Creating a Client

```julia
using Colonies

# Load configuration from environment variables
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()
```

## Examples

### Submitting a Process

Submit a job to run in a Docker container:

```julia
using Colonies

client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

conditions = Colonies.Conditions(
    colonyname=colonyname,
    executornames=String["dev-docker"],
    executortype="container-executor",
    walltime=60
)

kwargs = Dict{Any, Any}()
kwargs["cmd"] = "echo hello world"
kwargs["docker-image"] = "ubuntu:20.04"

funcspec = Colonies.FunctionSpec(
    funcname="execute",
    kwargs=kwargs,
    maxretries=3,
    maxexectime=55,
    conditions=conditions,
    label="myprocess",
    fs=Colonies.Filesystem()
)

process = Colonies.submit(client, funcspec, prvkey)
println("Process submitted: ", process.processid)

# Wait for completion
Colonies.wait(client, process, 60, prvkey)

# Get logs
logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

### Building an Executor

Create a custom executor that handles processes:

```julia
using Colonies
import Colonies.Crypto
using Random

client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

# Register executor
name = randstring(12)
executor_prvkey = Crypto.prvkey()
executor = Colonies.Executor(Crypto.id(executor_prvkey), "helloworld-executor", name, colonyname)
executor = Colonies.addexecutor(client, executor, colony_prvkey)
Colonies.approveexecutor(client, colonyname, executor.executorname, colony_prvkey)

# Main loop
while true
    try
        process = Colonies.assign(client, colonyname, 10, executor_prvkey)
        if process === nothing
            continue
        end

        funcname = get(process.spec, "funcname", "")
        if funcname == "helloworld"
            Colonies.addlog(client, process.processid, "Julia says Hello World!\n", executor_prvkey)
            Colonies.closeprocess(client, process.processid, executor_prvkey, ["Hello World!"])
        else
            Colonies.failprocess(client, process.processid, executor_prvkey, ["Invalid function"])
        end
    catch e
        println(e)
    end
end
```

### Submitting to a Custom Executor

```julia
using Colonies

client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

conditions = Colonies.Conditions(
    colonyname=colonyname,
    executortype="helloworld-executor"
)

funcspec = Colonies.FunctionSpec(
    funcname="helloworld",
    maxretries=3,
    maxexectime=55,
    conditions=conditions,
    label="helloworld-process"
)

process = Colonies.submit(client, funcspec, prvkey)
Colonies.wait(client, process, 60, prvkey)

logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

## Running the Examples

```bash
source docker-compose.env
cd examples
julia container.jl
julia helloworld_executor.jl
julia helloworld.jl
```

## API Overview

### Colony Management
- `addcolony`, `getcolony`, `getcolonies`, `removecolony`

### Executor Management
- `addexecutor`, `approveexecutor`, `rejectexecutor`
- `getexecutor`, `getexecutors`, `removeexecutor`
- `addfunction`

### Process Management
- `submit`, `assign`, `getprocess`, `getprocesses`
- `closeprocess`, `failprocess`, `removeprocess`, `removeallprocesses`
- `addattribute`, `setoutput`, `addchild`, `wait`

### Workflow Management
- `submitworkflow`, `getprocessgraph`, `getprocessgraphs`
- `removeprocessgraph`, `removeallprocessgraphs`

### Logging and Channels
- `addlog`, `getlogs`
- `channelappend`, `channelread`

### Blueprints
- `addblueprintdefinition`, `getblueprintdefinition`, `getblueprintdefinitions`, `removeblueprintdefinition`
- `addblueprint`, `getblueprint`, `getblueprints`, `updateblueprint`, `removeblueprint`
- `updateblueprintstatus`, `reconcileblueprint`

### Statistics
- `getstats`, `getfunctions`

See the [API Reference](docs/api-reference.md) for complete documentation.

## Installing the Colonies CLI

The Colonies CLI can be downloaded from [GitHub Releases](https://github.com/colonyos/colonies/releases).

```bash
sudo cp colonies /usr/local/bin
colonies --help
```

On macOS, grant permission in System Settings > Privacy & Security after first run.

Use the CLI to interact with the server:

```bash
source docker-compose.env
colonies executor ls
colonies process ps
colonies log search --text "Hello" -d 30
```

## License

MIT
