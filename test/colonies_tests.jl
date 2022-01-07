include("../src/Colonies.jl")
include("../src/Crypto.jl")

import .Colonies
import .Crypto
using Test

Base.exit_on_sigint(false)

global server_prvkey = "09545df1812e252a2a853cca29d7eace4a3fe2baad334e3b7141a98d43c31e7b"

function test_addcolony()
  prvkey = Crypto.prvkey()
  colonyid = Crypto.id(Crypto.prvkey())
  colony = Colonies.Colony(colonyid, "test_name2")
  added_colony = Colonies.addcolony(colony, server_prvkey)
  
  added_colony == colony
end

@testset begin
try
  @test test_addcolony()
catch err
  typeof(err) == InterruptException && rethrow(err)
  print(err)
end

end
