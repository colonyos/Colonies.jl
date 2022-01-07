using Pkg

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function fib(n)
  if n == 0
    return 0
  elseif n == 1
    return 1
  else
    return fib(n-2) + fib(n-1)
  end
end

function main(args)
  colony_prvkey = args[1]
  colonyid = Crypto.id(colony_prvkey)
  server = ColonyRuntime.ColoniesServer("localhost", 8080)

  # register a runtime
  println("- registering a new runtime to colony " * colonyid)
  runtime_prvkey = Crypto.prvkey()
  runtime = ColonyRuntime.Runtime(Crypto.id(runtime_prvkey), "fibonacci_solver", "fibonacci_solver", colonyid, "AMD Ryzen 9 5950X (32) @ 3.400GHz", 32, 80326, "NVIDIA GeForce RTX 2080 Ti Rev. A", 1)
  runtime = ColonyRuntime.addruntime(server, runtime, colony_prvkey)

  # and approve it so that can use the api
  println("- approving runtime " * runtime.runtimeid)
  ColonyRuntime.approveruntime(server, runtime.runtimeid, colony_prvkey)

  # request a waiting process
  try
    println("- assign process")
    assigned_process = ColonyRuntime.assignprocess(server, colonyid, runtime_prvkey)
    fibonacci_num = parse(Int64, assigned_process.attributes[1].value)
    println("  fibonacci_num: ", fibonacci_num)
    res = fib(fibonacci_num)
    println("  result: ", res)

    # add an attribute to the process 
    println("- add result attribute")
    attribute = ColonyRuntime.Attribute(assigned_process.processid, "result", string(res))
    ColonyRuntime.addattribute(server, attribute, runtime_prvkey)

    # close the process
    println("- close process")
    ColonyRuntime.closeprocess(server, assigned_process.processid, true, runtime_prvkey)
  catch err
    println(err)
    println("No waiting process found")
    return
  end

end

main(ARGS)
