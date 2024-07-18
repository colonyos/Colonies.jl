using Pkg
using Test

Pkg.activate("..")

using Colonies
using Colonies.Crypto

function main()
	client, colonyname, colony_prvkey, executorname, prvkey = Colonies.client()
	
	# conditions = Colonies.Conditions(colonyname, 
	#                                  String["dev-docker"],         # Exector names
	# 								 "container-executor",  # Executor Type
	# 								 String[],              # Dependencies
	# 								 1,			    # Number of nodes
	# 								 "1000m",		    # CPU
	# 								 0,    # Processes per node
	# 								 1,    # Processes per node
	# 								 "0Gi",			    # Memory
	# 								 "0Gi",			    # Memory
	# 								 Colonies.GPU("", "", 0, 0), # GPU 
	# 								 60)		    # Walltime
	conditions = Colonies.Conditions(colonyname=colonyname, 
	                                 executornames=String["dev-docker"],
									 executortype="container-executor",
									 gpu=Colonies.GPU("", "", 0, 0),
									 walltime=60)
    env = Dict{Any, Any}()
	kwargs = Dict{Any, Any}()
	kwargs["cmd"] = "echo hello world"
	kwargs["docker-image"] = "ubuntu:20.04"

    funcspec = Colonies.FunctionSpec("",                    # Node name
								     "execute",             # Function name
									 Any[],              # Args
									 kwargs,                # Kwargs
									 0,                    # Priority
									 -1,                    # Priority
									 55,                    # Max execution time
									 3,                     # Max number of retries
									 conditions,            # Conditions
									 "myprocess",           # Label
									 Colonies.Filesystem(), # Filesystem
									 env)                   # Environment
	
    added_process = Colonies.submit(client, funcspec, prvkey)
	println("Process submitted: ", added_process.processid)

	println("Waiting for process to finish ...")
	Colonies.wait(client, added_process, 60, prvkey)

	println("Process finished")
end

main()
