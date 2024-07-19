using Pkg
Pkg.activate("..")

using Colonies
using Colonies.Crypto
using Random

function main()
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
end

main()
