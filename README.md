[![codecov](https://codecov.io/gh/colonyos/Colonies.jl/branch/main/graph/badge.svg?token=EJJ6X2ST2L)](https://codecov.io/gh/colonyos/Colonies.jl) [![Julia](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml/badge.svg)](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml)

# Introduction
This repo contains a Julia SDK for the [Colonies API](https://github.com/colonyos/colonies), making it possible to implement ColonyOS applications in Julia.
See these [tutorials](https://github.com/colonyos/tutorials) for more information.

## Setting up a development environment
The following commands will use Docker Compose to set up and configure a Colonies server, a TimescaleDB, a Minio server, and a Docker Executor. To set up a production environment, it is recommended to use Kubernetes.

*Note!* The *docker-compose.env* file contains credentials and configuration and must be sourced before using the Colonies CLI command.

```bash
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.env;
source docker-compose.env;
wget https://raw.githubusercontent.com/colonyos/colonies/main/docker-compose.yml;
docker-compose up
```

Press control-c to exit.

To remove all data, type:
```bash
docker-compose down --volumes
```

For convinence, the **Colonies.client()** also reads all settings from the *docker-compose.env* file.
```julia
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()
```

## Installing the Colonies CLI
The Colonies CLI can be downloaded [here](https://github.com/colonyos/colonies/releases). Linux, Window, and Apple is supported.

Copy the binary to directory availble in the *PATH* e.g. **/usr/local/bin**.
```bash
sudo cp colonies /use/local/bin
```

```bash
colonies --help
```

On MacOS there is an error first time you run it. You need to grant the Colonies CLI permission to execute. Open System Settings, go to Privacy & Security, and click on the *Allow* button next to *colonies* to enable it to execute.

Start another terminal and run the command below to load the credentials and settings, allowing the Colonies CLI to connect to the Colonies server started with Docker compose.

```bash
source docker-compose.env
```

We can now interact with the Colonies server, and for example, list available executors.
```bash
colonies executor ls
```

```console
╭────────────┬────────────────────┬──────────┬─────────────────────╮
│ NAME       │ TYPE               │ LOCATION │ LAST HEARD FROM     │
├────────────┼────────────────────┼──────────┼─────────────────────┤
│ dev-docker │ container-executor │ n/a      │ 2024-06-29 13:37:27 │
╰────────────┴────────────────────┴──────────┴─────────────────────╯
```

## Submit a job to a Docker Executor
Let's submit a function spec to the Docker Executor. This will launch a Docker container running the command `echo hello world`.

```julia
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

conditions = Colonies.Conditions(colonyname=colonyname,
                                 executornames=String["dev-docker"],
                                 executortype="container-executor",
                                 walltime=60)

 env = Dict{Any, Any}()
 kwargs = Dict{Any, Any}()
 kwargs["cmd"] = "echo hello world"
 kwargs["docker-image"] = "ubuntu:20.04"

 funcspec = Colonies.FunctionSpec(funcname="execute",
                                  kwargs=kwargs,
                                  maxretries=3,
                                  maxexectime=55,
                                  conditions=conditions,
                                  label="myprocess",
                                  fs=Colonies.Filesystem())

process = Colonies.submit(client, funcspec, prvkey)
println("Process submitted: ", process.processid)

println("Waiting for process to finish ...")
Colonies.wait(client, process, 60, prvkey)
println("Process finished")

println("Getting 100 last logs")
logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

To run the example below, type:
```console
source docker-compose.env
cd examples
julia container.jl
```

```console
Activating project at `~/dev/github/colonyos/Colonies.jl`
Process submitted: 99d2b21ea7a911834aa882f777e3f1bcccdadb62fae4c7d8922571b6d70053c1
Waiting for process to finish ...
Process finished
Getting 100 last logs
Pulling from library/ubuntu
Digest: sha256:0b897358ff6624825fb50d20ffb605ab0eaea77ced0adb8c6a4b756513dec6fc
Status: Image is up to date for ubuntu:20.04
hello world
```

# Developing an Executor
To develop an executor, the following conceptual steps must be followed:

1. Generate a new private key.
2. Register the executor with the Colonies server using the colony's private key.
3. Call the assign function to receive process assignments.
4. Interpret the assigned process and perform some kind of computation.
5. Complete the process and set output values.
6. Repeat Step 3 to receive the next process assignment.

```julia
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

name = randstring(12)
executor_prvkey = Crypto.prvkey()
executor = Colonies.Executor(Crypto.id(executor_prvkey), "helloworld-executor", name, colonyname)

executor = Colonies.addexecutor(client, executor, colony_prvkey)
Colonies.approveexecutor(client, colonyname, executor.executorname, colony_prvkey)

while true
    try
        process = Colonies.assign(client, colonyname, 10, executor_prvkey)
        if process == nothing
            println("No process could be assigned, retrying ..")
            continue
        end
        if process.spec.funcname == "helloworld"
            println("Executor assigned process: ", process.processid)
            Colonies.addlog(client, process.processid, "Julia says Hello World!\n", executor_prvkey)
            Colonies.closeprocess(client, process.processid, executor_prvkey, ["Hello World!"])
        else
            Colonies.failprocess(client, process.processid, executor_prvkey, ["Invalid function name"])
        end
    catch e
        println(e)
    end
end
```

To run the example below, type:
```console
source docker-compose.env
cd examples
julia helloworld_executor.jl
```

We now have a new executor available.

```console
colonies executor ls
```

```console
╭──────────────┬─────────────────────┬──────────┬─────────────────────╮
│ NAME         │ TYPE                │ LOCATION │ LAST HEARD FROM     │
├──────────────┼─────────────────────┼──────────┼─────────────────────┤
│ V4uadfkRM2aP │ helloworld-executor │          │ 2024-07-19 14:58:38 │
│ dev-docker   │ container-executor  │ n/a      │ 2024-07-19 14:57:20 │
╰──────────────┴─────────────────────┴──────────┴─────────────────────╯
```

To create an helloworld process, we need to submit a function spec to the Colonies server.
```json
{
    "conditions": {
        "executortype": "helloworld-executor"
    },
    "funcname": "helloworld"
}
```

```console
source docker-compose.env
cd examples
colonies function submit --spec helloworld.json --follow
```

```console
INFO[0000] Process submitted                             ProcessId=56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6
INFO[0000] Printing logs from process                    ProcessId=56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6
Julia says Hello World!
INFO[0002] Process finished successfully                 ProcessId=56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6
```

We can also look up the process the Colonies CLI.
```console
colonies process get -p 56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6
```

```console
╭───────────────────────────────────────────────────────────────────────────────────────╮
│ Process                                                                               │
├────────────────────┬──────────────────────────────────────────────────────────────────┤
│ Id                 │ 56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6 │
│ IsAssigned         │ True                                                             │
│ InitiatorID        │ 3fc05cf3df4b494e95d6a3d297a34f19938f7daa7422ab0d4f794454133341ac │
│ Initiator          │ myuser                                                           │
│ AssignedExecutorID │ a8379b78f7b2dc40d600f61f21af500bc28f10050941f8ce23fce474f8bb9102 │
│ AssignedExecutorID │ Successful                                                       │
│ PriorityTime       │ 1721393484612965836                                              │
│ SubmissionTime     │ 2024-07-19 14:51:24                                              │
│ StartTime          │ 2024-07-19 14:51:24                                              │
│ EndTime            │ 2024-07-19 14:51:24                                              │
│ WaitDeadline       │ 0001-01-01 00:53:28                                              │
│ ExecDeadline       │ 0001-01-01 00:53:28                                              │
│ WaitingTime        │ 718.755ms                                                        │
│ ProcessingTime     │ 367.829ms                                                        │
│ Retries            │ 0                                                                │
│ Input              │                                                                  │
│ Output             │ Hello World!                                                     │
│ Errors             │                                                                  │
╰────────────────────┴──────────────────────────────────────────────────────────────────╯
╭──────────────────────────╮
│ Function Specification   │
├─────────────┬────────────┤
│ Func        │ helloworld │
│ Args        │ None       │
│ KwArgs      │ None       │
│ MaxWaitTime │ -1         │
│ MaxExecTime │ -1         │
│ MaxRetries  │ 0          │
│ Label       │            │
╰─────────────┴────────────╯
╭────────────────────────────────────────╮
│ Conditions                             │
├──────────────────┬─────────────────────┤
│ Colony           │ dev                 │
│ ExecutorNames    │ None                │
│ ExecutorType     │ helloworld-executor │
│ Dependencies     │                     │
│ Nodes            │ 0                   │
│ CPU              │ 0m                  │
│ Memory           │ 0Mi                 │
│ Processes        │ 0                   │
│ ProcessesPerNode │ 0                   │
│ Storage          │ 0Mi                 │
│ Walltime         │ 0                   │
│ GPUName          │                     │
│ GPUs             │ 0                   │
│ GPUPerNode       │ 0                   │
│ GPUMemory        │ 0Mi                 │
╰──────────────────┴─────────────────────╯
```

# Submitting jobs from Julia
```julia
client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()

conditions = Colonies.Conditions(colonyname=colonyname,
                                 executortype="helloworld-executor")

funcspec = Colonies.FunctionSpec(funcname="helloworld",
                                 maxretries=3,
                                 maxexectime=55,
                                 conditions=conditions,
                                 label="helloworld-process")

process = Colonies.submit(client, funcspec, prvkey)
println("Process submitted: ", process.processid)

println("Waiting for process to finish ...")
Colonies.wait(client, process, 60, prvkey)
println("Process finished")

println("Getting 100 last logs")
logs = Colonies.getlogs(client, colonyname, process.processid, 100, 0, prvkey)
for log in logs
    print(log.message)
end
```

To run the example, type:
```console
source docker-compose.env
cd examples
julia helloworld.jl
```

```console
Activating project at `~/dev/github/colonyos/Colonies.jl`
Process submitted: 9a4c74b2617711eb356fa85839554092b4a01abac380f51ff27a3796796ef32d
Waiting for process to finish ...
Process finished
Getting 100 last logs
Julia says Hello World!
```

# Logging
It is also possible to search for logs.
```console
colonies log search --text "Hello" -d 30
```

```console
INFO[0000] Searching for logs                            Count=20 Days=30 Text=Hello
╭──────────────┬──────────────────────────────────────────────────────────────────╮
│ Timestamp    │ 2024-07-19 14:57:47                                              │
│ ExecutorName │ V4uadfkRM2aP                                                     │
│ ProcessID    │ 9a4c74b2617711eb356fa85839554092b4a01abac380f51ff27a3796796ef32d │
│ Text         │ Julia says Hello World!                                          │
╰──────────────┴──────────────────────────────────────────────────────────────────╯
╭──────────────┬──────────────────────────────────────────────────────────────────╮
│ Timestamp    │ 2024-07-19 14:51:25                                              │
│ ExecutorName │ V4uadfkRM2aP                                                     │
│ ProcessID    │ 56edc0017579a62cd11c150b07df2bbf535c684722a3bb04000aabee7fdb02f6 │
│ Text         │ Julia says Hello World!                                          │
╰──────────────┴──────────────────────────────────────────────────────────────────╯
```

```console
colonies log get -p  9a4c74b2617711eb356fa85839554092b4a01abac380f51ff27a3796796ef32d
```

```console
Julia says Hello World!
```
