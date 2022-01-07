using Pkg
using Test

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function main(args)
  server_prvkey = args[1]
  println("server_prvkey: ", server_prvkey)

  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)

  println("colony prvkey: ", colony_prvkey)
  println("colonyid: ", colonyid)

  server = ColonyRuntime.ColoniesServer("localhost", 8080)

  colony = ColonyRuntime.Colony(colonyid, "my_colony")
  ColonyRuntime.addcolony(server, colony, server_prvkey)
end

main(ARGS)
