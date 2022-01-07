module Crypto 

using Pkg

# TODO
#  Warning: `Pkg.dir(pkgname, paths...)` is deprecated; instead, do `import ColonyRuntime; joinpath(dirname(pathof(ColonyRuntime)), "..", paths.
#  But, pathof just say LoadError: UndefVarError: ColonyRuntime not defined
crypto_lib_path = Pkg.dir("ColonyRuntime") * "lib/cryptolib.so"

function prvkey()
  prvkey_cstr = ccall((:prvkey, crypto_lib_path), Cstring, ())
  return unsafe_string(prvkey_cstr)
end

function id(prvkey::AbstractString)
  id_cstr = ccall((:id, crypto_lib_path), Cstring, (Cstring,), prvkey)
  return unsafe_string(id_cstr)
end

function sign(msg::AbstractString, prvkey::AbstractString)
  sig_cstr = ccall((:sign, crypto_lib_path), Cstring, (Cstring,Cstring), msg, prvkey)
  return unsafe_string(sig_cstr)
end

function hash(msg::AbstractString)
  msg_cstr = ccall((:hash, crypto_lib_path), Cstring, (Cstring,), msg)
  return unsafe_string(msg_cstr)
end

function recoverid(msg::AbstractString, sig::AbstractString)
  id_cstr = ccall((:recoverid, crypto_lib_path), Cstring, (Cstring,Cstring), msg, sig)
  return unsafe_string(id_cstr)
end

end
