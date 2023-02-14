using Pkg

Pkg.activate("../..")

using Colonies
using Colonies.Crypto

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
    client = Colonies.ColoniesClient("http", "localhost", 50080)

    # register an executor 
    println("- registering a new executor to colony " * colonyid)
    executor_prvkey = Crypto.prvkey()
    executor = Colonies.Executor(Crypto.id(executor_prvkey), "fibonacci_solver", "fibonacci_solver", colonyid, Colonies.PENDING)
    executor = Colonies.addexecutor(client, executor, colony_prvkey)

    # and approve it so that can use the api
    println("- approving executor " * executor.executorid)
    Colonies.approveexecutor(client, executor.executorid, colony_prvkey)

    # request a waiting process
    try
        println("- assign process")
        assigned_process = Colonies.assignprocess(client, colonyid, 10, executor_prvkey)
        fibonacci_num = parse(Int64, assigned_process.attributes[1].value)
        println("  fibonacci_num: ", fibonacci_num)
        res = fib(fibonacci_num)
        println("  result: ", res)

        # add an attribute to the process 
        println("- add result attribute")
        attribute = Colonies.Attribute(assigned_process.processid, colonyid, "output", string(res))
        Colonies.addattribute(client, attribute, executor_prvkey)

        # close the process
        println("- close process")
        Colonies.closeprocess(client, assigned_process.processid, executor_prvkey)
    catch err
        println(err)
        println("No waiting process found")
        return
    end

end

main(ARGS)
