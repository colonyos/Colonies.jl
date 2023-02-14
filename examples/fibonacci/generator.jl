using Pkg

Pkg.activate("../..")

using Colonies
using Colonies.Crypto

function main(args)
    colony_prvkey = "ba949fa134981372d6da62b6a56f336ab4d843b22c02a4257dcf7d0d73097514"
    colonyid = Crypto.id(colony_prvkey)
    client = Colonies.ColoniesClient("http", "localhost", 50080)

    # register an executor 
    println("- registering a new executor to colony " * colonyid)
    executor_prvkey = Crypto.prvkey()
    println("  executor_prvkey: ", executor_prvkey)
    println("  executorid: ", Crypto.id(executor_prvkey))

    executor = Colonies.Executor(Crypto.id(executor_prvkey), "fibonacci_generator", "fibonacci_generator", colonyid, Colonies.PENDING)
    executor = Colonies.addexecutor(client, executor, colony_prvkey)

    # and approve it so that can use the api
    println("- approving executor " * executor.executorid)
    Colonies.approveexecutor(client, executor.executorid, colony_prvkey)

    # submit a process spec
    println("- submitting process spec, fibonacci_num=" * args[1] * ", target_executor=fibonacci_solver")
    conditions = Colonies.Conditions(colonyid, [], "fibonacci_solver", [])
    env = Dict()
    env["fibonacci_num"] = args[1]
    processpec = Colonies.ProcessSpec("fibonacci", "fibonacci", [], 1, -1, -1, -1, conditions, env)

    process = Colonies.submitprocess(client, processpec, executor_prvkey)
    println("  processid: ", process.processid)
end

main(ARGS)
