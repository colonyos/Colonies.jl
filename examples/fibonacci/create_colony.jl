using Pkg
using Test

Pkg.activate("../..")

using Colonies
using Colonies.Crypto

function main()
    server_prvkey = "fcc79953d8a751bf41db661592dc34d30004b1a651ffa0725b03ac227641499d"
    colony_prvkey = Crypto.prvkey()
    colonyid = Crypto.id(colony_prvkey)

    println("colony prvkey: ", colony_prvkey)
    println("colonyid: ", colonyid)

    client = Colonies.ColoniesClient("http", "localhost", 50080)

    colony = Colonies.Colony(colonyid, "my_colony")
    addedcolony = Colonies.addcolony(client, colony, server_prvkey)
    println(addedcolony)
end

main()
