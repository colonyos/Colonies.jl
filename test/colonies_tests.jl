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

# ============================================================================
# Connection Tests
# ============================================================================

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

# ============================================================================
# Colony Tests
# ============================================================================

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

function test_getcolony()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    colony = Colonies.getcolony(client, colonyname, executor_prvkey)
    colony.name == colonyname
end

function test_getcolonies()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)

    colonies = Colonies.getcolonies(client, server_prvkey)
    length(colonies) >= 1
end

function test_removecolony()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)

    Colonies.removecolony(client, colonyname, server_prvkey)

    # Verify colony is removed by trying to get it
    try
        Colonies.getcolony(client, colonyname, server_prvkey)
        return false
    catch
        return true
    end
end

# ============================================================================
# Executor Tests
# ============================================================================

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

function test_getexecutor()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, executor = create_test_executor(client, colonyname, colony_prvkey)

    fetched = Colonies.getexecutor(client, colonyname, executor.executorname, executor_prvkey)
    fetched.executorname == executor.executorname
end

function test_getexecutors()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    create_test_executor(client, colonyname, colony_prvkey)
    create_test_executor(client, colonyname, colony_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    executors = Colonies.getexecutors(client, colonyname, executor_prvkey)
    length(executors) == 3
end

function test_rejectexecutor()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, executor = create_test_executor(client, colonyname, colony_prvkey)

    # Reject the executor - just verify the call succeeds
    Colonies.rejectexecutor(client, colonyname, executor.executorname, colony_prvkey)
    true
end

function test_removeexecutor()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, executor = create_test_executor(client, colonyname, colony_prvkey)

    Colonies.removeexecutor(client, colonyname, executor.executorname, colony_prvkey)

    try
        Colonies.getexecutor(client, colonyname, executor.executorname, colony_prvkey)
        return false
    catch
        return true
    end
end

# ============================================================================
# Process Tests
# ============================================================================

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

function test_removeprocess()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    added_process = Colonies.submit(client, funcspec, executor_prvkey)

    Colonies.removeprocess(client, added_process.processid, executor_prvkey)

    try
        Colonies.getprocess(client, added_process.processid, executor_prvkey)
        return false
    catch
        return true
    end
end

function test_removeallprocesses()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    Colonies.submit(client, funcspec, executor_prvkey)
    Colonies.submit(client, funcspec, executor_prvkey)
    Colonies.submit(client, funcspec, executor_prvkey)

    processes = Colonies.getprocesses(client, colonyname, Colonies.PENDING, 100, executor_prvkey)
    @assert length(processes) == 3

    Colonies.removeallprocesses(client, colonyname, colony_prvkey)

    processes = Colonies.getprocesses(client, colonyname, Colonies.PENDING, 100, executor_prvkey)
    length(processes) == 0
end

function test_setoutput()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    Colonies.submit(client, funcspec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyname, 10, executor_prvkey)
    Colonies.setoutput(client, assigned_process.processid, ["result1", "result2"], executor_prvkey)

    process = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    length(process.output) == 2
end

# ============================================================================
# Logging Tests
# ============================================================================

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

# ============================================================================
# Function Tests
# ============================================================================

function test_getfunctions()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, executor = create_test_executor(client, colonyname, colony_prvkey)

    func1 = Colonies.Function(executor.executorname, colonyname, "func1")
    func2 = Colonies.Function(executor.executorname, colonyname, "func2")
    Colonies.addfunction(client, func1, executor_prvkey)
    Colonies.addfunction(client, func2, executor_prvkey)

    functions = Colonies.getfunctions(client, colonyname, executor_prvkey)
    length(functions) == 2
end

# ============================================================================
# Statistics Tests
# ============================================================================

function test_getstats()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    funcspec = Colonies.FunctionSpec("test_proc", "test_func", String[], 1, -1, -1, -1, conditions, "")
    Colonies.submit(client, funcspec, executor_prvkey)
    Colonies.submit(client, funcspec, executor_prvkey)

    stats = Colonies.getstats(client, colonyname, executor_prvkey)
    stats.waitingprocesses == 2
end

# ============================================================================
# Workflow Tests
# ============================================================================

function test_submitworkflow()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions1 = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    spec1 = Colonies.FunctionSpec("task1", "func1", String[], 1, -1, -1, -1, conditions1, "")

    conditions2 = Colonies.Conditions(colonyname, String[], "test_executor_type", ["task1"])
    spec2 = Colonies.FunctionSpec("task2", "func2", String[], 1, -1, -1, -1, conditions2, "")

    workflow = Colonies.submitworkflow(client, colonyname, [spec1, spec2], executor_prvkey)

    length(workflow.processgraphid) == 64 && length(workflow.processids) == 2
end

function test_getprocessgraph()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    spec = Colonies.FunctionSpec("task1", "func1", String[], 1, -1, -1, -1, conditions, "")

    workflow = Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)

    fetched = Colonies.getprocessgraph(client, workflow.processgraphid, executor_prvkey)
    fetched.processgraphid == workflow.processgraphid
end

function test_getprocessgraphs()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    spec = Colonies.FunctionSpec("task1", "func1", String[], 1, -1, -1, -1, conditions, "")

    Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)
    Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)

    workflows = Colonies.getprocessgraphs(client, colonyname, 100, executor_prvkey)
    length(workflows) >= 2
end

function test_removeprocessgraph()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    spec = Colonies.FunctionSpec("task1", "func1", String[], 1, -1, -1, -1, conditions, "")

    workflow = Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)

    Colonies.removeprocessgraph(client, workflow.processgraphid, executor_prvkey)

    try
        Colonies.getprocessgraph(client, workflow.processgraphid, executor_prvkey)
        return false
    catch
        return true
    end
end

function test_removeallprocessgraphs()
    colony_prvkey, colonyname = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyname, colony_prvkey)

    conditions = Colonies.Conditions(colonyname, String[], "test_executor_type", String[])
    spec = Colonies.FunctionSpec("task1", "func1", String[], 1, -1, -1, -1, conditions, "")

    Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)
    Colonies.submitworkflow(client, colonyname, [spec], executor_prvkey)

    Colonies.removeallprocessgraphs(client, colonyname, colony_prvkey)

    workflows = Colonies.getprocessgraphs(client, colonyname, 100, executor_prvkey)
    length(workflows) == 0
end

# ============================================================================
# Run Tests
# ============================================================================

@testset begin
    try
        # Connection tests
        @test test_failed_connect()

        # Colony tests
        @test test_addcolony()
        @test test_addcolony_invalid_cred()
        @test test_getcolony()
        @test test_getcolonies()
        @test test_removecolony()

        # Executor tests
        @test test_addexecutor()
        @test test_addexecutor_duplicate_name()
        @test test_getexecutor()
        @test test_getexecutors()
        @test test_rejectexecutor()
        @test test_removeexecutor()

        # Process tests
		@test test_submit()
		@test test_getprocess()
		@test test_getprocesses()
        @test test_assign()
        @test test_addattribute()
        @test test_closeprocess_successful()
        @test test_closeprocess_failed()
        @test test_removeprocess()
        @test test_removeallprocesses()
        @test test_setoutput()

        # Function tests
        @test test_addfunc()
        @test test_getfunctions()

        # Logging tests
        @test test_addlog()

        # Statistics tests
        @test test_getstats()

        # Workflow tests
        @test test_submitworkflow()
        @test test_getprocessgraph()
        @test test_getprocessgraphs()
        @test test_removeprocessgraph()
        @test test_removeallprocessgraphs()
    catch err
        typeof(err) == InterruptException && rethrow(err)
        print(err)
    end

end
