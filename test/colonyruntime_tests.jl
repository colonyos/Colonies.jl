#include("../src/ColonyRuntime.jl")
#include("../src/Crypto.jl")

#import .ColonyRuntime
#import .Crypto

using Pkg
using Test

Pkg.activate("..")

using Test
using ColonyRuntime
using ColonyRuntime.Crypto

Base.exit_on_sigint(false)

global server_prvkey = "09545df1812e252a2a853cca29d7eace4a3fe2baad334e3b7141a98d43c31e7b"

server = ColonyRuntime.ColoniesServer("localhost", 8080)

function test_addcolony()
  colonyid = Crypto.id(Crypto.prvkey())
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)
  
  added_colony == colony
end

function test_addruntime()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
 
  added_runtime == runtime
end

function test_approveruntime()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
  true # an exception will be raised if it does not work 
end

function test_submitprocess()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  # we don't bother testing all process attrbiutes, at least the process was assing a 64 chars process id 
  length(added_process.processid) == 64
end

function test_getprocess()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  process_from_server = ColonyRuntime.getprocess(server, added_process.processid, runtime_prvkey)
  process_from_server.processid == added_process.processid
end

function test_assignprocess()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid, "amd", 1, 1024, "nvidia", 1, ColonyRuntime.PENDING)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
  assigned_process.processid == added_process.processid
end

function test_addattribute()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
  assigned_process.processid == added_process.processid

  attribute = ColonyRuntime.Attribute(assigned_process.processid, "test_result", "test_result_value")
  added_attribute = ColonyRuntime.addattribute(server, attribute, runtime_prvkey)

  added_attribute.key == "test_result" 
end

function test_closeprocess_successful()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
  assigned_process.processid == added_process.processid

  attribute = ColonyRuntime.Attribute(assigned_process.processid, "test_result", "test_result_value")
  added_attribute = ColonyRuntime.addattribute(server, attribute, runtime_prvkey)

  ColonyRuntime.closeprocess(server, assigned_process.processid, true, runtime_prvkey)

  process_from_server = ColonyRuntime.getprocess(server, assigned_process.processid, runtime_prvkey)
  process_from_server.state == ColonyRuntime.SUCCESS
end

function test_closeprocess_failed()
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)
  colony = ColonyRuntime.Colony(colonyid, "test_name2")
  added_colony = ColonyRuntime.addcolony(server, colony, server_prvkey)

  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "test_runtime_type", "test_runtime_name", colonyid)
  added_runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)
  ColonyRuntime.approveruntime(server, added_runtime.runtimeid, colony_prvkey)
 
  conditions = ColonyRuntime.Conditions(colonyid, [], "test_runtime_type", 1, 1024, 1)
  env = Dict()
  env["args"] = "test_args"
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  added_process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)

  assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
  assigned_process.processid == added_process.processid

  attribute = ColonyRuntime.Attribute(assigned_process.processid, "test_result", "test_result_value")
  added_attribute = ColonyRuntime.addattribute(server, attribute, runtime_prvkey)

  ColonyRuntime.closeprocess(server, assigned_process.processid, false, runtime_prvkey)

  closed_process = ColonyRuntime.getprocess(server, assigned_process.processid, runtime_prvkey)
  closed_process.state == ColonyRuntime.FAILED
end

@testset begin
try
  @test test_addcolony()
  @test test_addruntime()
  @test test_approveruntime()
  @test test_submitprocess()
  @test test_getprocess()
  @test test_assignprocess()
  @test test_addattribute()
  @test test_closeprocess_successful()
  @test test_closeprocess_failed()
catch err
  typeof(err) == InterruptException && rethrow(err)
  print(err)
end

end
