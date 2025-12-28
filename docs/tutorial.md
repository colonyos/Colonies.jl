# Colonies.jl Tutorial

This tutorial will guide you through using Colonies.jl to interact with ColonyOS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Setting Up the Development Environment](#setting-up-the-development-environment)
4. [Basic Concepts](#basic-concepts)
5. [Submitting Your First Process](#submitting-your-first-process)
6. [Building an Executor](#building-an-executor)
7. [Working with Workflows](#working-with-workflows)
8. [Using Channels for Real-Time Communication](#using-channels-for-real-time-communication)
9. [Logging and Monitoring](#logging-and-monitoring)

---

## Prerequisites

- Julia 1.6 or later
- Docker and Docker Compose (for the development environment)
- The Colonies CLI (optional, but recommended)

## Installation

Add Colonies.jl to your Julia project:

```julia
using Pkg
Pkg.add(url="https://github.com/colonyos/Colonies.jl")
```

Or add it to your Project.toml:

```toml
[deps]
Colonies = "..."
```

## Setting Up the Development Environment

The easiest way to get started is using Docker Compose, which sets up a complete ColonyOS environment including the server, database, and a Docker executor.

### 1. Download the configuration files

```bash
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.env
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.yml
```

### 2. Start the services

```bash
source docker-compose.env
docker-compose up -d
```

### 3. Verify the setup

```bash
colonies executor ls
```

You should see the Docker executor listed:

```
╭────────────┬────────────────────┬──────────┬─────────────────────╮
│ NAME       │ TYPE               │ LOCATION │ LAST HEARD FROM     │
├────────────┼────────────────────┼──────────┼─────────────────────┤
│ dev-docker │ container-executor │ Local    │ 2025-12-28 00:58:45 │
╰────────────┴────────────────────┴──────────┴─────────────────────╯
```

### 4. Install the Colonies CLI (optional)

Download from [GitHub Releases](https://github.com/colonyos/colonies/releases) and add to your PATH:

```bash
sudo cp colonies /usr/local/bin/
```

---

## Basic Concepts

### Colonies and Executors

- **Colony**: A distributed runtime environment consisting of networked executors
- **Executor**: A worker that pulls and executes processes
- **Process**: A computational workload defined by a FunctionSpec

### Authentication

ColonyOS uses cryptographic signatures for authentication. There are three levels of access:

1. **Server Owner**: Can manage colonies
2. **Colony Owner**: Can manage executors within a colony
3. **Executor**: Can submit and execute processes

### Creating a Client

The simplest way to create a client is using environment variables:

```julia
using Colonies
import Colonies.Crypto

# Load client configuration from environment
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()
```

Or create a client manually:

```julia
client = Colonies.ColoniesClient("http", "localhost", 50080)
```

---

## Submitting Your First Process

Let's submit a simple process to the Docker executor.

### Example: Running a Docker Container

```julia
using Colonies
import Colonies.Crypto

# Create client from environment
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

# Define execution conditions
conditions = Colonies.Conditions(
    colonyname=colonyname,
    executornames=String["dev-docker"],
    executortype="container-executor",
    walltime=60
)

# Define the function to execute
kwargs = Dict{Any, Any}()
kwargs["cmd"] = "echo 'Hello from Docker!'"
kwargs["docker-image"] = "ubuntu:20.04"

funcspec = Colonies.FunctionSpec(
    funcname="execute",
    kwargs=kwargs,
    maxretries=3,
    maxexectime=55,
    conditions=conditions,
    label="hello-docker",
    fs=Colonies.Filesystem()
)

# Submit the process
process = Colonies.submit(client, funcspec, prvkey)
println("Process submitted: ", process.processid)

# Wait for completion
println("Waiting for process to finish...")
Colonies.wait(client, process, 60, prvkey)
println("Process finished!")

# Get the logs
logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

### Understanding the Output

The process goes through these states:
1. **WAITING** (0): Waiting for an executor
2. **RUNNING** (1): Assigned to an executor and running
3. **SUCCESS** (2): Completed successfully
4. **FAILED** (3): Failed with errors

---

## Building an Executor

An executor is a program that:
1. Registers with the colony
2. Polls for work using `assign()`
3. Executes the assigned process
4. Reports results using `closeprocess()` or `failprocess()`

### Example: Hello World Executor

```julia
using Colonies
import Colonies.Crypto
using Random

# Create client
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

# Generate a unique executor identity
name = randstring(12)
executor_prvkey = Crypto.prvkey()
executor_id = Crypto.id(executor_prvkey)

# Create and register the executor
executor = Colonies.Executor(executor_id, "helloworld-executor", name, colonyname)
executor = Colonies.addexecutor(client, executor, colony_prvkey)

# Approve the executor (requires colony owner key)
Colonies.approveexecutor(client, colonyname, executor.executorname, colony_prvkey)

println("Executor registered: ", name)
println("Waiting for processes...")

# Main executor loop
while true
    try
        # Wait for a process (10 second timeout)
        process = Colonies.assign(client, colonyname, 10, executor_prvkey)

        if process === nothing
            println("No process available, waiting...")
            continue
        end

        println("Assigned process: ", process.processid)

        # Check the function name
        funcname = get(process.spec, "funcname", "")

        if funcname == "helloworld"
            # Add a log message
            Colonies.addlog(client, process.processid, "Julia says Hello World!\n", executor_prvkey)

            # Close successfully with output
            Colonies.closeprocess(client, process.processid, executor_prvkey, ["Hello World!"])
            println("Process completed successfully")
        else
            # Unknown function, fail the process
            Colonies.failprocess(client, process.processid, executor_prvkey, ["Unknown function: $funcname"])
            println("Process failed: unknown function")
        end

    catch e
        println("Error: ", e)
        sleep(1)
    end
end
```

### Submitting a Job to Your Executor

Create a function spec that targets your executor:

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
    label="my-hello"
)

process = Colonies.submit(client, funcspec, prvkey)
println("Submitted: ", process.processid)

Colonies.wait(client, process, 60, prvkey)

logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

---

## Working with Workflows

Workflows (ProcessGraphs) allow you to define DAGs of dependent processes.

### Example: Sequential Workflow

```julia
using Colonies

client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

conditions = Colonies.Conditions(
    colonyname=colonyname,
    executortype="helloworld-executor"
)

# Define two tasks where task2 depends on task1
task1 = Colonies.FunctionSpec(
    nodename="task1",
    funcname="helloworld",
    maxexectime=60,
    conditions=conditions
)

# task2 has a dependency on task1
conditions2 = Colonies.Conditions(
    colonyname=colonyname,
    executortype="helloworld-executor",
    dependencies=["task1"]
)

task2 = Colonies.FunctionSpec(
    nodename="task2",
    funcname="helloworld",
    maxexectime=60,
    conditions=conditions2
)

# Submit the workflow
graph = Colonies.submitworkflow(client, colonyname, [task1, task2], prvkey)
println("Workflow submitted: ", graph.processgraphid)
println("Process IDs: ", graph.processids)
```

### Dynamically Adding Children

You can add child processes to a running workflow:

```julia
# After assigning a process that's part of a workflow
child_spec = Colonies.FunctionSpec(
    funcname="child-task",
    maxexectime=60,
    conditions=conditions
)

child = Colonies.addchild(client, process.processgraphid, process.processid, child_spec, prvkey)
println("Added child: ", child.processid)
```

---

## Using Channels for Real-Time Communication

Channels provide real-time messaging between processes and external clients.

### Writing to a Channel

```julia
# Inside an executor, after assigning a process
Colonies.channelappend(client, process.processid, "output", 1, "First message", executor_prvkey)
Colonies.channelappend(client, process.processid, "output", 2, "Second message", executor_prvkey)
Colonies.channelappend(client, process.processid, "output", 3, "Done", executor_prvkey, msgtype="end")
```

### Reading from a Channel

```julia
# Read all messages after sequence 0
entries = Colonies.channelread(client, processid, "output", 0, 100, prvkey)

for entry in entries
    println("Seq $(entry.sequence) [$(entry.msgtype)]: $(entry.data)")
end
```

### Message Types

- `"data"` - Regular data message (default)
- `"end"` - Signals end of stream
- `"error"` - Error message

---

## Logging and Monitoring

### Adding Logs from an Executor

```julia
Colonies.addlog(client, processid, "Starting computation...\n", executor_prvkey)
Colonies.addlog(client, processid, "Step 1 complete\n", executor_prvkey)
Colonies.addlog(client, processid, "Finished!\n", executor_prvkey)
```

### Getting Colony Statistics

```julia
stats = Colonies.getstats(client, colonyname, prvkey)

println("Executors: ", stats.executors)
println("Waiting processes: ", stats.waitingprocesses)
println("Running processes: ", stats.runningprocesses)
println("Successful: ", stats.successfulprocesses)
println("Failed: ", stats.failedprocesses)
```

### Listing Processes by State

```julia
# Get waiting processes
waiting = Colonies.getprocesses(client, colonyname, Colonies.WAITING, 100, prvkey)
println("Waiting: ", length(waiting))

# Get running processes
running = Colonies.getprocesses(client, colonyname, Colonies.RUNNING, 100, prvkey)
println("Running: ", length(running))
```

---

## Clean Up

When you're done, stop the Docker Compose services:

```bash
docker-compose down
```

To also remove all data:

```bash
docker-compose down --volumes
```

---

## Next Steps

- See the [API Reference](api-reference.md) for complete function documentation
- Check out the [examples](../examples/) directory for more code samples
- Visit the [ColonyOS tutorials](https://github.com/colonyos/tutorials) for advanced topics
