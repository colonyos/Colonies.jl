using Pkg

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function main(args)
    colony_prvkey = "ba949fa134981372d6da62b6a56f336ab4d843b22c02a4257dcf7d0d73097514"
    colonyid = Crypto.id(colony_prvkey)
    client = ColonyRuntime.ColoniesClient("http", "localhost", 50080)

    # register a runtime
    println("- registering a new runtime to colony " * colonyid)
    runtime_prvkey = Crypto.prvkey()
    println("  runtime_prvkey: ", runtime_prvkey)
    println("  runtimeid: ", Crypto.id(runtime_prvkey))

    runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "fibonacci_generator", "fibonacci_generator", colonyid, "", 1, 1, "", 1, ColonyRuntime.PENDING)
    runtime = ColonyRuntime.addruntime(client, runtime, colony_prvkey)

    # and approve it so that can use the api
    println("- approving runtime " * runtime.runtimeid)
    ColonyRuntime.approveruntime(client, runtime.runtimeid, colony_prvkey)

    # submit a process spec
    println("- submitting process spec, fibonacci_num=" * args[1] * ", target_runtime=fibonacci_solver")
    conditions = ColonyRuntime.Conditions(colonyid, [], "fibonacci_solver", [])
    env = Dict()
    env["fibonacci_num"] = args[1]
    processpec = ColonyRuntime.ProcessSpec("fibonacci", "fibonacci", [], 1, -1, -1, -1, conditions, env)

    process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)
    println("  processid: ", process.processid)
end

main(ARGS)
