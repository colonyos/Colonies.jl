using Pkg

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function fib(n)
    if n == 0
        return 0
    elseif n == 1
        return 1
    else
        return fib(n - 2) + fib(n - 1)
    end
end

function main(args)
    colony_prvkey = "ba949fa134981372d6da62b6a56f336ab4d843b22c02a4257dcf7d0d73097514"
    colonyid = Crypto.id(colony_prvkey)
    client = ColonyRuntime.ColoniesClient("http", "localhost", 50080)

    # register a runtime
    println("- registering a new runtime to colony " * colonyid)
    runtime_prvkey = Crypto.prvkey()
    runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "fibonacci_solver", "fibonacci_solver", colonyid, "", 1, 1, "", 1, ColonyRuntime.PENDING)
    runtime = ColonyRuntime.addruntime(client, runtime, colony_prvkey)

    # and approve it so that can use the api
    println("- approving runtime " * runtime.runtimeid)
    ColonyRuntime.approveruntime(client, runtime.runtimeid, colony_prvkey)

    # request a waiting process
    try
        println("- assign process")
        assigned_process = ColonyRuntime.assignprocess(client, colonyid, 10, runtime_prvkey)
        fibonacci_num = parse(Int64, assigned_process.attributes[1].value)
        println("  fibonacci_num: ", fibonacci_num)
        res = fib(fibonacci_num)
        println("  result: ", res)

        # add an attribute to the process 
        println("- add result attribute")
        attribute = ColonyRuntime.Attribute(assigned_process.processid, colonyid, "output", string(res))
        ColonyRuntime.addattribute(client, attribute, runtime_prvkey)

        # close the process
        println("- close process")
        ColonyRuntime.closeprocess(client, assigned_process.processid, true, runtime_prvkey)
    catch err
        println(err)
        println("No waiting process found")
        return
    end

end

main(ARGS)
