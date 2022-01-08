[![codecov](https://codecov.io/gh/colonyos/ColonyRuntime.jl/branch/main/graph/badge.svg?token=EJJ6X2ST2L)](https://codecov.io/gh/colonyos/ColonyRuntime.jl)

[![Julia](https://github.com/colonyos/ColonyRuntime.jl/actions/workflows/julia.yaml/badge.svg?branch=main)](https://github.com/colonyos/ColonyRuntime.jl/actions/workflows/julia.yaml)

# Introduction
This repo contains a Julia implementation of the [ColonyRuntime API](https://github.com/colonyos/colonies), making it possible to implement Colony applications i Julia.

## Fibonacci example
* A **generator** application generate pending processes containing a number as an environmental variable. 
* A **solver** applications is assigned a pending process and execute the process by calculate the fibonacci number of the number. It sets result as an attribute to the process and then close the process.
* If there are many solver application, they will compete assigning processes.
* Example code can be found in [here](https://github.com/colonyos/ColonyRuntime.jl/tree/main/examples/fibonacci)

## Create a colony
This requires access to a Colonies Server and server private key. Only server owners are allowed to create new Colonies.

```julia
server_prvkey = "09545df1812e252a2a853cca29d7eace4a3fe2baad334e3b7141a98d43c31e7b" 
server = ColonyRuntime.ColoniesServer("localhost", 8080)

colony_prvkey = Crypto.prvkey()
colonyid = Crypto.id(colony_prvkey)
colony = ColonyRuntime.Colony(colonyid, "my_colony")
ColonyRuntime.addcolony(server, colony, server_prvkey)

println("colony prvkey: ", colony_prvkey)
println("colonyid: ", colonyid)
```

```console
julia create_colony.jl 

colony prvkey: 8c062f688d091139d1afabbe62e156d2152a23171b52c6015b73d73f020fe147
colonyid: 71f3d0b3bc67d2ddc416cdcc16d6f7612fb06cf3eb5a268ad49198004586fbf2
```

## Fibonacci task generator

```julia
...
colony_prvkey = args[1]
colonyid = Crypto.id(colony_prvkey)
server = ColonyRuntime.ColoniesServer("localhost", 8080)

# submit a process spec
conditions = ColonyRuntime.Conditions(colonyid, [], "fibonacci_solver", 1, 1024, 0) # 1 core, 1024 MiB memory, no GPU
env = Dict()
env["fibonacci_num"] = args[2]
processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)
...
```

```console
julia generator.jl 8c062f688d091139d1afabbe62e156d2152a23171b52c6015b73d73f020fe147 12

- registering a new runtime to colony 71f3d0b3bc67d2ddc416cdcc16d6f7612fb06cf3eb5a268ad49198004586fbf2
  runtime_prvkey: aeaad74ffd6437c9ac5b5584c5134552e049fdb1e98a02aa9d44c14d05c199f5
  runtimeid: eda3749d7977007cc58633cf9779b4cd82aeb5b74cc6888ef779bfed89b7a95b
- approving runtime eda3749d7977007cc58633cf9779b4cd82aeb5b74cc6888ef779bfed89b7a95b
- submitting process spec, fibonacci_num=12, target_runtime=fibonacci_solver
  processid: 1a514f7e1819c2c17bea037248da3a905959545a2ce2ed930f07593eba494c06
```

### Look up the process using the Colonies CLI
``` console
./bin/colonies process get --runtimeid c455cf241e3fc5b9e55cc8bc4c9b3f062c56f66ab2006cd2d9d2147ee4e9a7dc --runtimeprvkey 4609781d4167c49a8197de15e628393b654bc5eff031e59c437677534f82f5a7 --processid 1a514f7e1819c2c17bea037248da3a905959545a2ce2ed930f07593eba494c06

Process:
+-------------------+------------------------------------------------------------------+
| ID                | 1a514f7e1819c2c17bea037248da3a905959545a2ce2ed930f07593eba494c06 |
| IsAssigned        | False                                                            |
| AssignedRuntimeID | None                                                             |
| State             | Waiting                                                          |
| SubmissionTime    | 2022-01-07T23:02:14.80559Z                                       |
| StartTime         | 0001-01-01T00:00:00Z                                             |
| EndTime           | 0001-01-01T00:00:00Z                                             |
| Deadline          | 0001-01-01T00:00:00Z                                             |
| Retries           | 0                                                                |
+-------------------+------------------------------------------------------------------+

Requirements:
+----------------+------------------------------------------------------------------+
| ColonyID       | 71f3d0b3bc67d2ddc416cdcc16d6f7612fb06cf3eb5a268ad49198004586fbf2 |
| RuntimeIDs     | None                                                             |
| RuntimeType    | fibonacci_solver                                                 |
| Memory         | 1024                                                             |
| CPU Cores      | 1                                                                |
| Number of GPUs | 0                                                                |
| Timeout        | -1                                                               |
| Max retries    | -1                                                               |
+----------------+------------------------------------------------------------------+

Attributes:
+------------------------------------------------------------------+---------------+-------+------+
|                                ID                                |      KEY      | VALUE | TYPE |
+------------------------------------------------------------------+---------------+-------+------+
| 47e07826caf4e1b4a81e37732309082953d218c2917fb0d39bfec79cef38b328 | fibonacci_num |    12 | Env  |
+------------------------------------------------------------------+---------------+-------+------+
```

## Fibonacci task solver 

```julia
...
# request a waiting process
assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
fibonacci_num = parse(Int64, assigned_process.attributes[1].value)
res = fib(fibonacci_num)

# add an attribute to the process
println("- add result attribute")
attribute = ColonyRuntime.Attribute(assigned_process.processid, "result", string(res))
ColonyRuntime.addattribute(server, attribute, runtime_prvkey)
...
```

```console
julia solver.jl 8c062f688d091139d1afabbe62e156d2152a23171b52c6015b73d73f020fe147

- registering a new runtime to colony 71f3d0b3bc67d2ddc416cdcc16d6f7612fb06cf3eb5a268ad49198004586fbf2
- approving runtime 14eb16aa0052ff84dce164a982317b7d92478a0ad47b56c8c8e60cb37910d973
- assign process
  fibonacci_num: 12
  result: 144
- add result attribute
- close process
```

### Look up the process using the Colonies CLI
```console
./bin/colonies process get --runtimeid c455cf241e3fc5b9e55cc8bc4c9b3f062c56f66ab2006cd2d9d2147ee4e9a7dc --runtimeprvkey 4609781d4167c49a8197de15e628393b654bc5eff031e59c437677534f82f5a7 --processid 1a514f7e1819c2c17bea037248da3a905959545a2ce2ed930f07593eba494c06
Process:
+-------------------+------------------------------------------------------------------+
| ID                | 1a514f7e1819c2c17bea037248da3a905959545a2ce2ed930f07593eba494c06 |
| IsAssigned        | True                                                             |
| AssignedRuntimeID | 1cf8c9289e9ad01718040f3a9d75639fe6d903cc830ce285f8dd6dd45adce344 |
| State             | Successful                                                       |
| SubmissionTime    | 2022-01-07T23:02:14.80559Z                                       |
| StartTime         | 2022-01-07T23:09:57.197727Z                                      |
| EndTime           | 2022-01-07T23:09:57.77686Z                                       |
| Deadline          | 0001-01-01T00:00:00Z                                             |
| Retries           | 0                                                                |
+-------------------+------------------------------------------------------------------+

Requirements:
+----------------+------------------------------------------------------------------+
| ColonyID       | 71f3d0b3bc67d2ddc416cdcc16d6f7612fb06cf3eb5a268ad49198004586fbf2 |
| RuntimeIDs     | None                                                             |
| RuntimeType    | fibonacci_solver                                                 |
| Memory         | 1024                                                             |
| CPU Cores      | 1                                                                |
| Number of GPUs | 0                                                                |
| Timeout        | -1                                                               |
| Max retries    | -1                                                               |
+----------------+------------------------------------------------------------------+

Attributes:
+------------------------------------------------------------------+---------------+-------+------+
|                                ID                                |      KEY      | VALUE | TYPE |
+------------------------------------------------------------------+---------------+-------+------+
| 47e07826caf4e1b4a81e37732309082953d218c2917fb0d39bfec79cef38b328 | fibonacci_num |    12 | Env  |
| 33fe2261bab2db663adf496b4b6170e8c5f48c2b23da6e1289f2f911b5d88f97 | result        |   144 | Out  |
+------------------------------------------------------------------+---------------+-------+------+
```

Note the **result** attribute.
