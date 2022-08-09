using Pkg
using Test

Pkg.activate("..")

using Test
using ColonyRuntime
using ColonyRuntime.Crypto
using Random

Base.exit_on_sigint(false)

global server_prvkey = "fcc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"

client = ColonyRuntime.ColoniesClient("http", "localhost", 50080)

function create_test_colony(client::ColonyRuntime.ColoniesClient, server_prvkey::String)
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)
    colony = ColonyRuntime.Colony(colonyid, "test_colony")
    ColonyRuntime.addcolony(client, colony, server_prvkey)

    colony_prvkey, colony.colonyid
end

function create_test_runtime(client::ColonyRuntime.ColoniesClient, colonyid::String, colony_prvkey::String)
    name = randstring(12)
    runtime_prvkey = Crypto.prvkey()
    runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name_" * name, colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
    added_runtime = ColonyRuntime.addruntime(client, runtime, colony_prvkey)
    ColonyRuntime.approveruntime(client, added_runtime.runtimeid, colony_prvkey)

    runtime_prvkey, added_runtime
end

function test_failed_connect()
    try
        client = ColonyRuntime.ColoniesClient("http", "localhost", 60080)
        colonyid = Crypto.id(Crypto.prvkey())
        colony = ColonyRuntime.Colony(colonyid, "test_colony")
        ColonyRuntime.addcolony(client, colony, server_prvkey)
    catch err
        println(err)
        return true
    end

    return false
end

function test_addcolony()
    colonyid = Crypto.id(Crypto.prvkey())
    colony = ColonyRuntime.Colony(colonyid, "test_colony")
    added_colony = ColonyRuntime.addcolony(client, colony, server_prvkey)

    added_colony == colony
end

function test_addcolony_invalid_cred()
    colonyid = Crypto.id(Crypto.prvkey())
    colony = ColonyRuntime.Colony(colonyid, "test_colony")
    invalid_server_prvkey = "acc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
    try
        ColonyRuntime.addcolony(client, colony, invalid_server_prvkey)
    catch
        return true
    end

    return false
end

function test_addruntime()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    _, runtime = create_test_runtime(client, colonyid, colony_prvkey)
    length(runtime.runtimeid) == 64
end

function test_addruntime_duplicate_name()
    try
        colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
        runtime_prvkey = Crypto.prvkey()
        runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "", 1, 1, "", 1, ColonyRuntime.PENDING)
        ColonyRuntime.addruntime(client, runtime, colony_prvkey)
        ColonyRuntime.addruntime(client, runtime, colony_prvkey)
    catch
        return true
    end

    return false
end

function test_submitprocess()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    # we don't bother testing all process attrbiutes, at least the process was assing a 64 chars process id
    length(added_process.processid) == 64
end

function test_getprocess()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    process_from_server = ColonyRuntime.getprocess(client, added_process.processid, runtime_prvkey)
    process_from_server.processid == added_process.processid
end

function test_getprocesses()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)
    ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    processes_from_server = ColonyRuntime.getprocesses(client, colonyid, ColonyRuntime.PENDING, 100, runtime_prvkey)
    length(processes_from_server) == 2
end

function test_assignprocess()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    assigned_process = ColonyRuntime.assignprocess(client, colonyid, 10, runtime_prvkey)  # wait max 10 seconds for an assignment
    assigned_process.processid == added_process.processid
end

function test_assignprocess_failed()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    try
        ColonyRuntime.assignprocess(client, colonyid, 1, runtime_prvkey)
    catch
        return true
    end

    return false
end

function test_addattribute()
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)
    colony = ColonyRuntime.Colony(colonyid, "test_colony_6")
    added_colony = ColonyRuntime.addcolony(client, colony, server_prvkey)

    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    assigned_process = ColonyRuntime.assignprocess(client, colonyid, 10, runtime_prvkey)
    assigned_process.processid == added_process.processid

    attribute = ColonyRuntime.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = ColonyRuntime.addattribute(client, attribute, runtime_prvkey)

    added_attribute.key == "test_result"
end

function test_closeprocess_successful()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    assigned_process = ColonyRuntime.assignprocess(client, colonyid, 10, runtime_prvkey)
    assigned_process.processid == added_process.processid

    attribute = ColonyRuntime.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = ColonyRuntime.addattribute(client, attribute, runtime_prvkey)

    ColonyRuntime.closeprocess(client, assigned_process.processid, true, runtime_prvkey)

    process_from_server = ColonyRuntime.getprocess(client, assigned_process.processid, runtime_prvkey)
    process_from_server.state == ColonyRuntime.SUCCESS
end

function test_closeprocess_failed()
    colony_prvkey, colonyid = create_test_colony(client, server_prvkey)
    runtime_prvkey, _ = create_test_runtime(client, colonyid, colony_prvkey)

    conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", [])
    env = Dict()
    env["args"] = "test_args"
    processpec = ColonyRuntime.ProcessSpec("test_proc", "test_func", [], 1, -1, -1, -1, conditions, env)
    added_process = ColonyRuntime.submitprocess(client, processpec, runtime_prvkey)

    assigned_process = ColonyRuntime.assignprocess(client, colonyid, 10, runtime_prvkey)
    assigned_process.processid == added_process.processid

    attribute = ColonyRuntime.Attribute(assigned_process.processid, colonyid, "test_result", "test_result_value")
    added_attribute = ColonyRuntime.addattribute(client, attribute, runtime_prvkey)

    ColonyRuntime.closeprocess(client, assigned_process.processid, false, runtime_prvkey)

    closed_process = ColonyRuntime.getprocess(client, assigned_process.processid, runtime_prvkey)
    closed_process.state == ColonyRuntime.FAILED
end

@testset begin
    try
        @test test_failed_connect()
        @test test_addcolony()
        @test test_addcolony_invalid_cred()
        @test test_addruntime()
        @test test_addruntime_duplicate_name()
        @test test_submitprocess()
        @test test_getprocess()
        @test test_getprocesses()
        @test test_assignprocess()
        @test test_assignprocess_failed()
        @test test_addattribute()
        @test test_closeprocess_successful()
        @test test_closeprocess_failed()
    catch err
        typeof(err) == InterruptException && rethrow(err)
        print(err)
    end

end
