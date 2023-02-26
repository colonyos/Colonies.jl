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
    colony = Colonies.Colony(colonyid, "test_colony")
    Colonies.addcolony(client, colony, server_prvkey)

    colony_prvkey, colony.colonyid
end

function create_test_executor(client::Colonies.ColoniesClient, colonyid::String, colony_prvkey::String)
    name = randstring(12)
    executor_prvkey = Crypto.prvkey()
    executor = Colonies.Executor(Crypto.id(executor_prvkey), "test_executor_type", "test_executor_name_" * name, colonyid, Colonies.PENDING)
    added_executor = Colonies.addexecutor(client, executor, colony_prvkey)
    Colonies.approveexecutor(client, added_executor.executorid, colony_prvkey)

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
    colony = Colonies.Colony(colonyid, "test_colony")
    added_colony = Colonies.addcolony(client, colony, server_prvkey)

    added_colony == colony
end

function test_addcolony_invalid_cred()
    colonyid = Crypto.id(Crypto.prvkey())
    colony = Colonies.Colony(colonyid, "test_colony")
    invalid_server_prvkey = "acc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
    try
        Colonies.addcolony(client, colony, invalid_server_prvkey)
    catch
        return true
    end

    return false
end

function test_addexecutor()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    _, executor = create_test_executor(client, colonyid, colony_prvkey)
    length(executor.executorid) == 64
end

function test_addexecutor_duplicate_name()
    try
        colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
        executor_prvkey = Crypto.prvkey()
        executor = Colonies.Executor(Crypto.id(executor_prvkey), "test_executor_type", "test_executor_name", colonyid, Colonies.PENDING)
        Colonies.addexecutor(client, executor, colony_prvkey)
        Colonies.addexecutor(client, executor, colony_prvkey)
    catch
        return true
    end

    return false
end

function test_submit()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    # we don't bother testing all process attrbiutes, at least the process was assing a 64 chars process id
    length(added_process.processid) == 64
end

function test_getprocess()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    process_from_server = Colonies.getprocess(client, added_process.processid, executor_prvkey)
    process_from_server.processid == added_process.processid
end

function test_getprocesses()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    Colonies.submit(client, processpec, executor_prvkey)
    Colonies.submit(client, processpec, executor_prvkey)

    processes_from_server = Colonies.getprocesses(client, colonyid, Colonies.PENDING, 100, executor_prvkey)
    length(processes_from_server) == 2
end

function test_assign()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyid, 10, executor_prvkey)  # wait max 10 seconds for an assignment
    assigned_process.processid == added_process.processid
end

function test_addattribute()
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)
    colony = Colonies.Colony(colonyid, "test_colony_6")
    added_colony = Colonies.addcolony(client, colony, server_prvkey)

    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyid, 10, executor_prvkey)
    assigned_process.processid == added_process.processid

    attribute = Colonies.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = Colonies.addattribute(client, attribute, executor_prvkey)

    added_attribute.key == "test_result"
end

function test_closeprocess_successful()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyid, 10, executor_prvkey)
    assigned_process.processid == added_process.processid

    attribute = Colonies.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = Colonies.addattribute(client, attribute, executor_prvkey)

    Colonies.closeprocess(client, assigned_process.processid, executor_prvkey)

    process_from_server = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    process_from_server.state == Colonies.SUCCESS
end

function test_closeprocess_failed()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    executor_prvkey, _ = create_test_executor(client, colonyid, colony_prvkey)

    conditions = Colonies.Conditions(colonyid, [], "test_executor_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = Colonies.FuncSpec("test_proc", "test_func", [], 1, 1, -1, -1, -1, conditions, "", env)
    added_process = Colonies.submit(client, processpec, executor_prvkey)

    assigned_process = Colonies.assign(client, colonyid, 10, executor_prvkey)
    assigned_process.processid == added_process.processid

    attribute = Colonies.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = Colonies.addattribute(client, attribute, executor_prvkey)

    Colonies.failprocess(client, assigned_process.processid, executor_prvkey)

    closed_process = Colonies.getprocess(client, assigned_process.processid, executor_prvkey)
    closed_process.state == Colonies.FAILED
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
    catch err
        typeof(err) == InterruptException && rethrow(err)
        print(err)
    end

end
