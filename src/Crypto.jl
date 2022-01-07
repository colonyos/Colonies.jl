module Crypto 

function prvkey()
  prvkey_cstr = ccall((:prvkey, "../lib/cryptolib.so"), Cstring, ())
  return unsafe_string(prvkey_cstr)
end

function id(prvkey::AbstractString)
  id_cstr = ccall((:id, "../lib/cryptolib.so"), Cstring, (Cstring,), prvkey)
  return unsafe_string(id_cstr)
end

function sign(msg::AbstractString, prvkey::AbstractString)
  sig_cstr = ccall((:sign, "../lib/cryptolib.so"), Cstring, (Cstring,Cstring), msg, prvkey)
  return unsafe_string(sig_cstr)
end

function hash(msg::AbstractString)
  msg_cstr = ccall((:hash, "../lib/cryptolib.so"), Cstring, (Cstring,), msg)
  return unsafe_string(msg_cstr)
end

function recoverid(msg::AbstractString, sig::AbstractString)
  id_cstr = ccall((:recoverid, "../lib/cryptolib.so"), Cstring, (Cstring,Cstring), msg, sig)
  return unsafe_string(id_cstr)
end

end
