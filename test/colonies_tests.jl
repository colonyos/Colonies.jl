using Base: add_with_overflow
using Pkg
using Test

Pkg.activate("..")

using Test
using Colonies
using Colonies.Crypto
using Random

Base.exit_on_sigint(false)

global server_prvkey = "fcc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"

client = Colonies.ColoniesClient("http", "localhost", 50080)

function create_test_colony(client::Colonies.ColoniesClient, server_prvkey::String)
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)
	colonyname = randstring(12)
    colony = Colonies.Colony(colonyid, "test_colony" * colonyname)
    Colonies.addcolony(client, colony, server_prvkey)

    colony_prvkey, colony.name
end

function create_test_executor(client::Colonies.ColoniesClient, colonyname::String, colony_prvkey::String)
    name = randstring(12)
    executor_prvkey = Crypto.prvkey()
    executor = Colonies.Executor(Crypto.id(executor_prvkey), "test_executor_type", "test_executor_name_" * name, colonyname)

    added_executor = Colonies.addexecutor(client, executor, colony_prvkey)
    Colonies.approveexecutor(client, colonyname, added_executor.executorname, colony_prvkey)
    executor_prvkey, added_executor
end

function test_failed_connect()
    try
        client = Colonies.ColoniesClient("http", "localhost", 60080)
        colonyid = Crypto.id(Crypto.prvkey())
        colony = Colonies.Colony(colonyid, "test_colony")
        Colonies.addcolony(client, colony, server_prvkey)
    catch err
        println(err)
        return true
    end

    return false
end

function test_addcolony()
    colonyid = Crypto.id(Crypto.prvkey())
	random_name = randstring(12)
    colony = Colonies.Colony(colonyid, "test_colony_" * random_name)
    added_colony = Colonies.addcolony(client, colony, server_prvkey)

    added_colony == colony
end

function test_addcolony_invalid_cred()
    colonyid = Crypto.id(Crypto.prvkey())
	random_name = randstring(12)
    colony = Colonies.Colony(colonyid, "test_colony_" * random_name)
    invalid_server_prvkey = "acc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
    try
        Colonies.addcolony(client, colony, invalid_server_prvkey)
    catch
        return true
    end

    return false
end

function test_addexecutor()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    _, executor = create_test_executor(client, colonyname, colony_prvkey)
	length(executor.executorid) == 64
end

function test_addexecutor_duplicate_name()
    try
        colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
        executor_prvkey = Crypto.prvkey()
    	executorid = Crypto.id(executor_prvkey)
		name = randstring(12)

		executor = Executor(
    		executorid,
    		"test_executor_type", 
    		name, 
    		colonyname, 
    		Colonies.PENDING, 
    		false, 
    		"2024-07-14T11:55:00.119702+02:00", 
    		"2022-08-08T10:22:25.819199+02:00", 
    		Location(0.0, 0.0, ""), 
    		Capabilities(Hardware("", 0, "", "", "", GPU("", "", 0, 0)), Software("", "", "")), 
    		Allocations(Dict{String, Project}())
		)


        Colonies.addexecutor(client, executor, colony_prvkey)
        Colonies.addexecutor(client, executor, colony_prvkey)
    catch
        return true
    end

    return false
end

function test_submit()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
	env = Dict{String, String}()
    env["args"] = "test_args"

    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_proc",
        args = ["test_arg1", "test_arg2", "test_arg3"],
        priority = 50,
        maxwaittime = -1,
        maxexectime = 3600,
        maxretries = 1,
        conditions = conditions,
        label = "test_label",
        env = env)
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    length(added_process.processid) == 64
end

function test_addfunc()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, executor = create_test_executor(client, colonyname, colony_prvkey)

    func = Colonies.Function(executor.executorname, colonyname, "testfunc")
    added_function = Colonies.addfunction(client, func, executor_prvkey)

    length(added_function.functionid) == 64
end

function test_getprocess()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
	env = Dict{String, String}()
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    process_from_server = Colonies.getprocess(client, added_process.processid, executor_prvkey)
    process_from_server.processid == added_process.processid
end

function test_getprocesses()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    Colonies.submit(client, funcspec, executor_prvkey)
    Colonies.submit(client, funcspec, executor_prvkey)

    processes_from_server = Colonies.getprocesses(client, colonyname, Colonies.PENDING, 100, executor_prvkey)
    length(processes_from_server) == 2
end

function test_assign()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)  # wait max 10 seconds for an assignment
    assigned_process.processid == added_process.processid
end

function test_unmarshal()

    payload="""
    {
        "processid":"aeadb23995409ed35ce8cb6c54f0659ac89d07503cc2f80e5a6941bf694247ea",
        "initiatorid":"3fc05cf3df4b494e95d6a3d297a34f19938f7daa7422ab0d4f794454133341ac",
        "initiatorname":"initiator",
        "assignedexecutorid":"8a60e7414a36c5b8c36e0d165c6734fb0ab52d57a538b8af2025ad16c9151d71",
        "isassigned":true,
        "state":1,
        "prioritytime":1742982430593794312,
        "submissiontime":"2025-03-26T10:47:10.593794+01:00",
        "starttime":"2025-03-26T13:54:30.68260703Z",
        "endtime":"2025-03-26T14:50:13.299076+01:00",
        "waitdeadline":"0001-01-01T00:53:28+00:53",
        "execdeadline":"2025-03-26T14:50:12.562314+01:00",
        "retries":5,
        "attributes":[],
        "spec":{
            "nodename":"nodename",
            "funcname":"funcname",
            "args":[
                "48d3d16c-0a27-11f0-ab0d-5eb9e77fccdd,1611615602816220273",
                "48dacc1a-0a27-11f0-ab0d-5eb9e77fccdd,1611615602819340322",
                "48ddbd1c-0a27-11f0-ab0d-5eb9e77fccdd,1611615602848220274"
                ],
            "kwargs":{},
            "priority":0,
            "maxwaittime":0,
            "maxexectime":300,
            "maxretries":5,
            "conditions":{
                "colonyname":"colonyname",
                "executornames": ["executorname1", "executorname2"],
                "executortype":"executortype",
                "dependencies":[],
                "nodes":0,
                "cpu":"0m",
                "processes":0,
                "processespernode":0,
                "mem":"0Mi",
                "storage":"0Mi",
                "gpu":{
                    "name":"",
                    "mem":"0Mi",
                    "count":0,
                    "nodecount":0
                },
                "walltime":0
            },
            "label":"label",
            "fs":{
                "mount":"",
                "snapshots":null,
                "dirs":null
            },
            "env":{}
        },
        "waitforparents":false,
        "parents":[],
        "children":[],
        "processgraphid":"449db1dfe4ef50a1c1d3535b03b5b036dc38026a21be84a7fa0a0720d906c53e",
        "in":[],
        "out":[],
        "errors":[]
    }"""

    process = Colonies.unmarshaljson(payload, Colonies.Process)
    process.processid == "aeadb23995409ed35ce8cb6c54f0659ac89d07503cc2f80e5a6941bf694247ea"
    process.initiatorid == "3fc05cf3df4b494e95d6a3d297a34f19938f7daa7422ab0d4f794454133341ac"
    process.initiatorname == "initiator"
    process.spec.funcname == "funcname"
    process.spec.conditions.executortype == "executortype"
    process.spec.args == [
        "48d3d16c-0a27-11f0-ab0d-5eb9e77fccdd,1611615602816220273",
        "48dacc1a-0a27-11f0-ab0d-5eb9e77fccdd,1611615602819340322",
        "48ddbd1c-0a27-11f0-ab0d-5eb9e77fccdd,1611615602848220274"
    ]
end

function test_addattribute()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    attribute = Colonies.Attribute(assigned_process.processid, colonyname, "test_result", "test_result_value")
    added_attribute = Colonies.addattribute(client, attribute, executor_prvkey)

    added_attribute.key == "test_result"
end

function test_closeprocess_successful()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    Colonies.closeprocess(client, assigned_process.processid, executor_prvkey)

    process_from_server = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    process_from_server.state == Colonies.SUCCESS
end

function test_closeprocess_failed()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    Colonies.failprocess(client, assigned_process.processid, executor_prvkey)

    closed_process = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    closed_process.state == Colonies.FAILED
end

function test_addlog()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec(
        nodename = "test_proc",
        funcname = "test_func",
        args = String[],
        priority = 1,
        maxwaittime = -1,
        maxexectime = -1,
        maxretries = -1,
        conditions = conditions,
        label = "")

    Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)

	Colonies.addlog(client, assigned_process.processid, "test_log_1", executor_prvkey)
	Colonies.addlog(client, assigned_process.processid, "test_log_2", executor_prvkey)

    Colonies.closeprocess(client, assigned_process.processid, executor_prvkey)

	logs = Colonies.getlogs(client, colonyname, assigned_process.processid, 10, 0, executor_prvkey)
	length(logs) == 2 
end

@testset begin
    try
        @test test_failed_connect()
        @test test_addcolony()
        @test test_addcolony_invalid_cred()
        @test test_addexecutor()
        @test test_addexecutor_duplicate_name()
		@test test_submit()
		@test test_getprocess()
		@test test_getprocesses()
        @test test_assign()
        @test test_unmarshal()
        @test test_addattribute()
        @test test_closeprocess_successful()
        @test test_closeprocess_failed()
        @test test_addfunc()
        @test test_addlog()
    catch err
        typeof(err) == InterruptException && rethrow(err)
        print(err)
    end

end
