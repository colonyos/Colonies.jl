[![codecov](https://codecov.io/gh/colonyos/Colonies.jl/branch/main/graph/badge.svg?token=EJJ6X2ST2L)](https://codecov.io/gh/colonyos/Colonies.jl) [![Julia](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml/badge.svg)](https://github.com/colonyos/Colonies.jl/actions/workflows/julia.yaml)

# Introduction
This repo contains a Julia implementation of the [Colonies API](https://github.com/colonyos/colonies), making it possible to implement Colonies Executors in Julia.

## Start a Colonies server 
```console
source devenv
colonies dev
```

## Create a colony
This requires access to a Colonies server and server private key. Only server owners are allowed to create new Colonies.

```julia
server_prvkey = "fcc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
colony_prvkey = Crypto.prvkey()
colonyid = Crypto.id(colony_prvkey)

println("colony prvkey: ", colony_prvkey)
println("colonyid: ", colonyid)

client = Colonies.ColoniesClient("http", "localhost", 50080)

colony = Colonies.Colony(colonyid, "my_colony")
addedcolony = Colonies.addcolony(client, colony, server_prvkey)
println(addedcolony)
```

```console
julia create_colony.jl 
```

Output:
```console
colony prvkey: 8449d00c8b128700904f2ae0cdbf7c025cb42cd920487798adeacb06f0216a3e
colonyid: f79dab605840c81a1d6d871f2964ed43120a13c218d04a06205f704e274af2ee
Colonies.Colony("f79dab605840c81a1d6d871f2964ed43120a13c218d04a06205f704e274af2ee", "my_colony")
```

## Fibonacci task generator
```julia
...
# submit a process spec
conditions = Colonies.Conditions(colonyid, [], "fibonacci_solver", [])
env = Dict()
env["fibonacci_num"] = args[2]
processpec = Colonies.ProcessSpec("fibonacci", "fibonacci", [], 1, -1, -1, -1, conditions, 
process = Colonies.submitprocess(server, processpec, executor_prvkey)
...
```

```console
julia generator.jl 12                                                          11:21:25
```

Output:
```console
- registering a new executor to colony 4787a5071856a4acf702b2ffcea422e3237a679c681314113d86139461290cf4
  executor_prvkey: 4354efffdc4a2bfb304121aecbdbaa9a51be91b6c2608ebc0321b727fe225830
  executorid: 3a76f43bfecf6d9168c29c43101e35e2d31799720eae6e57330fa98890b6cdb9
- approving executor 3a76f43bfecf6d9168c29c43101e35e2d31799720eae6e57330fa98890b6cdb9
- submitting process spec, fibonacci_num=12, target_executor=fibonacci_solver
  processid: 6e9ff157d25a6aa417a8400915249d4b8accc19d2e760d97d18aca59ea23544f
```

## Fibonacci task solver 
```julia
...
# request a waiting process, wait max 10 seconds for an assignment
assigned_process = Colonies.assignprocess(server, colonyid, 10, executor_prvkey)  
fibonacci_num = parse(Int64, assigned_process.attributes[1].value)
res = fib(fibonacci_num)

# add an attribute to the process
println("- add result attribute")
attribute = Colonies.Attribute(assigned_process.processid, "result", string(res))
Colonies.addattribute(server, attribute, executor_prvkey)
...
```

```console
julia solver.jl
```

Output:
```console
- registering a new executor to colony 4787a5071856a4acf702b2ffcea422e3237a679c681314113d86139461290cf4
- approving executor 6b6c186cfd9be0c7d6fbefa121e21aeeea1f1a95853d6eaf170ac2549390dfb7
- assign process
  fibonacci_num: 12
  result: 144
- add result attribute
- close process
```

### Look up the process using the Colonies CLI
```console
./bin/colonies process get --processid 6e9ff157d25a6aa417a8400915249d4b8accc19d2e760d97d18aca59ea23544f
```

```console
INFO[0000] Starting a Colonies client                    Insecure=true ServerHost=localhost ServerPort=50080
Process:
+--------------------+------------------------------------------------------------------+
| ID                 | 6e9ff157d25a6aa417a8400915249d4b8accc19d2e760d97d18aca59ea23544f |
| IsAssigned         | True                                                             |
| AssignedExecutorID | 6b6c186cfd9be0c7d6fbefa121e21aeeea1f1a95853d6eaf170ac2549390dfb7 |
| State              | Successful                                                       |
| Priority           | 1                                                                |
| SubmissionTime     | 2022-08-09 11:26:38                                              |
| StartTime          | 2022-08-09 11:27:32                                              |
| EndTime            | 2022-08-09 11:27:32                                              |
| WaitDeadline       | 0001-01-01 01:12:12                                              |
| ExecDeadline       | 0001-01-01 01:12:12                                              |
| WaitingTime        | 54.073752s                                                       |
| ProcessingTime     | 491.359ms                                                        |
| Retries            | 0                                                                |
| ErrorMsg           |                                                                  |
+--------------------+------------------------------------------------------------------+

ProcessSpec:
+-------------+-----------+
| Func        | fibonacci |
| Args        | None      |
| MaxWaitTime | -1        |
| MaxExecTime | -1        |
| MaxRetries  | -1        |
| Priority    | 1         |
+-------------+-----------+

Conditions:
+--------------+------------------------------------------------------------------+
| ColonyID     | 4787a5071856a4acf702b2ffcea422e3237a679c681314113d86139461290cf4 |
| ExecutorIDs  | None                                                             |
| ExecutorType | fibonacci_solver                                                 |
+--------------+------------------------------------------------------------------+

Attributes:
+------------------------------------------------------------------+---------------+-------+------+
|                                ID                                |      KEY      | VALUE | TYPE |
+------------------------------------------------------------------+---------------+-------+------+
| 24cb6bbf7b1a7120affcb63cec61dd377c208fa88909d7828acd07fe9846f081 | fibonacci_num | 12    | Env  |
| b40d0861d02dc5618f3b336c751856e4e028686484144b315e1ee000749e6e72 | output        | 144   | Out  |
+------------------------------------------------------------------+---------------+-------+------+
```

Note the **result** attribute.
