using Pkg
using Test

Pkg.activate("../..")

using ColonyRuntime
using ColonyRuntime.Crypto

function main()
    server_prvkey = "fcc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)

    println("colony prvkey: ", colony_prvkey)
    println("colonyid: ", colonyid)

    client = ColonyRuntime.ColoniesClient("http", "localhost", 50080)

    colony = ColonyRuntime.Colony(colonyid, "my_colony")
    addedcolony = ColonyRuntime.addcolony(client, colony, server_prvkey)
    println(addedcolony)
end

main()
