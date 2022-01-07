include("../src/Crypto.jl")
import .Crypto

function main(args)
  colony_prvkey = Crypto.prvkey()
  colonyid = Crypto.id(colony_prvkey)

  println("colony prvkey: ", colony_prvkey)
  println("colonyid: ", colonyid)
end

main()
