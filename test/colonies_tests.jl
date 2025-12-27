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
    		"",
    		Capabilities(),
    		Allocations()
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
	
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "", env)
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
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    process_from_server = Colonies.getprocess(client, added_process.processid, executor_prvkey)
    process_from_server.processid == added_process.processid
end

function test_getprocesses()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    Colonies.submit(client, funcspec, executor_prvkey)
    Colonies.submit(client, funcspec, executor_prvkey)

    processes_from_server = Colonies.getprocesses(client, colonyname, Colonies.PENDING, 100, executor_prvkey)
    length(processes_from_server) == 2
end

function test_assign()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)  # wait max 10 seconds for an assignment
    assigned_process.processid == added_process.processid
end

function test_addattribute()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    attribute = Colonies.Attribute(assigned_process.processid, colonyname, "test_result", "test_result_value")
    added_attribute = Colonies.addattribute(client, attribute, executor_prvkey)

    added_attribute.key == "test_result"
end

function test_closeprocess_successful()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    Colonies.closeprocess(client, assigned_process.processid, executor_prvkey)

    process_from_server = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    process_from_server.state == Colonies.SUCCESS
end

function test_closeprocess_failed()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    Colonies.failprocess(client, assigned_process.processid, executor_prvkey)

    closed_process = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    closed_process.state == Colonies.FAILED
end

function test_addlog()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

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
