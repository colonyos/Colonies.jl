using Pkg

Pkg.activate("..")

using Colonies
using Colonies.Crypto

function main()
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
end

main()
