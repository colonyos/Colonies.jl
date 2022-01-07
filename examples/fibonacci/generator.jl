using Pkg

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function main(args)
  colony_prvkey = args[1]
  colonyid = Crypto.id(colony_prvkey)
  server = ColonyRuntime.ColoniesServer("localhost", 8080)

  # register a runtime
  println("- registering a new runtime to colony " * colonyid)
  runtime_prvkey = Crypto.prvkey()
  println("  runtime_prvkey: ", runtime_prvkey)
  println("  runtimeid: ", Crypto.id(runtime_prvkey))

  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "fibonacci_generator", "fibonacci_generator", colonyid, "AMD Ryzen 9 5950X (32) @ 3.400GHz", 32, 80326, "NVIDIA GeForce RTX 2080 Ti Rev. A", 1)
  runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)

  # and approve it so that can use the api
  println("- approving runtime " * runtime.runtimeid)
  ColonyRuntime.approveruntime(server, runtime.runtimeid, colony_prvkey)

  # submit a process spec
  println("- submitting process spec, fibonacci_num=" * args[2] * ", target_runtime=fibonacci_solver")
  
  conditions = ColonyRuntime.Conditions(colonyid, [], "fibonacci_solver", 1, 1024, 0) # 1 core, 1024 Mib memory, no GPU
  env = Dict()
  env["fibonacci_num"] = args[2]
  
  processpec = ColonyRuntime.ProcessSpec(-1, -1, conditions, env)
  process = ColonyRuntime.submitprocess(server, processpec, runtime_prvkey)
  println("  processid: ", process.processid)
end

main(ARGS)
