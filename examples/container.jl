using Pkg

Pkg.activate("..")

using Colonies
using Colonies.Crypto

function main()
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
end

main()
