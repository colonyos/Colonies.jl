using Pkg
using Test

Pkg.activate("..")

using Colonies

function test_prvkey()
  prvkey = Colonies.Crypto.prvkey()
  return length(prvkey)
end

function test_id()
  id = Colonies.Crypto.id(Colonies.Crypto.prvkey())
  return length(id)
end

function test_sign() 
  prvkey = "d6eb959e9aec2e6fdc44b5862b269e987b8a4d6f2baca542d8acaa97ee5e74f6"
  msg = "test_msg"
  sig = Colonies.Crypto.sign(msg, prvkey)
  return length(sig)
end

function test_hash() 
  msg = "test_msg"
  hash = Colonies.Crypto.hash(msg)
  return length(hash)
end

function test_recoverid() 
  msg = "test_msg"
  prvkey = Colonies.Crypto.prvkey()
  sig = Colonies.Crypto.sign(msg, prvkey)
  recoverid = Colonies.Crypto.recoverid(msg, sig)

  return recoverid == Colonies.Crypto.id(prvkey)
end


@testset begin 
@test test_prvkey() == 64 
@test test_id() == 64 
@test test_sign() == 130
@test test_hash() == 64
@test test_recoverid() 

end
