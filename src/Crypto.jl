module Crypto

using Random, SHA, Pkg

A = BigInt(0)
N = BigInt(115792089237316195423570985008687907852837564279074904382605163141518161494337)
Gx = BigInt(55066263022277343669578718895168534326250603453777594175500187360389116729240)
Gy = BigInt(32670510020758816978083085130507043184471273380659243275938904335757337482424)
G = (Gx, Gy)
P = BigInt(115792089237316195423570985008687907853269984665640564039457584007908834671663)

function prvkey()
    random_bytes = rand(UInt8, 32)
    hash_obj = sha3_256(random_bytes)
    return bytes2hex(hash_obj)
end

function hex2bytes(hex::String)::Vector{UInt8}
    parse.(UInt8, [hex[i:i+1] for i in 1:2:length(hex)], base=16)
end

function bytes2hex(bytes::Vector{UInt8})::String
    join([string(b, base=16, pad=2) for b in bytes])
end

function sign(msg::String, prv_hex::String)::String
    prv_bytes = hex2bytes(prv_hex)
    hash_bytes = sha3_256(msg)
    s = ecdsa_raw_sign(hash_bytes, prv_bytes)
    vb = int_to_byte(s[1])
    rb = pad32(int_to_big_endian(s[2]))
    sb = pad32(int_to_big_endian(s[3]))
    sig = vcat(rb, sb, vb)
    sig_hex = bytes2hex(sig)
    return sig_hex
end

function jacobian_double(p::Tuple{BigInt, BigInt, BigInt})::Tuple{BigInt, BigInt, BigInt}
    if p[2] == 0
        return (BigInt(0), BigInt(0), BigInt(0))
    end

	ysq = mod(p[2] ^ 2, P)
    S = mod(4 * p[1] * ysq, P)
    M = mod(3 * p[1] ^ 2 + A * p[3] ^ 4, P)
    nx = mod(M ^ 2 - 2 * S, P)
    ny = mod(M * (S - nx) - 8 * ysq ^ 2, P)
    nz = mod(2 * p[2] * p[3], P)
    return (nx, ny, nz)
end

function jacobian_add(p::Tuple{BigInt, BigInt, BigInt}, q::Tuple{BigInt, BigInt, BigInt})::Tuple{BigInt, BigInt, BigInt}
    if p[2] == 0
        return q
    end
    if q[2] == 0
        return p
    end
    
    U1 = mod(p[1] * q[3]^2, P)
    U2 = mod(q[1] * p[3]^2, P)
    S1 = mod(p[2] * q[3]^3, P)
    S2 = mod(q[2] * p[3]^3, P)
    
    if U1 == U2
        if S1 != S2
            return (BigInt(0), BigInt(0), BigInt(1))
        end
        return jacobian_double(p)
    end
    
    H = U2 - U1
    R = S2 - S1
    H2 = mod(H * H, P)
    H3 = mod(H * H2, P)
    U1H2 = mod(U1 * H2, P)
    nx = mod(R^2 - H3 - 2 * U1H2, P)
    ny = mod(R * (U1H2 - nx) - S1 * H3, P)
    nz = mod(H * p[3] * q[3], P)
    
    return (nx, ny, nz)
end

function fast_multiply(a::Tuple{BigInt, BigInt}, n::BigInt)::Tuple{BigInt, BigInt}
	j = to_jacobian(a)
	m = jacobian_multiply(j, n)
	res = from_jacobian(m)
	return res
end

function inv(a::BigInt, n::BigInt)::BigInt
    if a == 0
        throw(ArgumentError("Inverse does not exist for zero"))
    end
    lm, hm = BigInt(1), BigInt(0)
    low, high = mod(a, n), n
    while low > 1
        r = div(high, low)
        nm, new = hm - lm * r, high - low * r
        lm, hm = nm, lm
        low, high = new, low
    end
    return mod(lm, n)
end

function jacobian_multiply(a::Tuple{BigInt, BigInt, BigInt}, n::BigInt)::Tuple{BigInt, BigInt, BigInt}
    if a[2] == 0 || n == 0
    	return (BigInt(0), BigInt(0), BigInt(1))
    end
    if n == 1
		return a 
    end
    if n < 0 || n >= N
		mul_res = jacobian_multiply(a, BigInt(mod(n, N)))
		return mul_res
    end
	if mod(n ,2) == 0
		mul_res = jacobian_multiply(a, BigInt(n ÷ 2))
		double_res = jacobian_double(mul_res)
		return double_res
	elseif mod(n, 2) == 1
		add_res = jacobian_add(jacobian_double(jacobian_multiply(a, BigInt(n ÷ 2))), a)
		return add_res
	else	
		error("Invariant: Unreachable code path")
	end
end

function to_jacobian(p::Tuple{BigInt, BigInt})::Tuple{BigInt, BigInt, BigInt}
    return (p[1], p[2], BigInt(1))
end

function from_jacobian(p::Tuple{BigInt, BigInt, BigInt})::Tuple{BigInt, BigInt}
    z = inv(p[3], P)
    return ((p[1] * z^2) % P, (p[2] * z^3) % P)
end

function big_endian_to_int(value::Vector{UInt8})::BigInt
    result = BigInt(0)
    for byte in value
        result = (result << 8) | BigInt(byte)
    end
    return result
end

function int_to_big_endian(value::BigInt)::Vector{UInt8}
    if value == 0
        return [UInt8(0)]
    end

    nbytes = max(ceil(Int, (bit_length(value) + 7) / 8), 1)
    bytes = Vector{UInt8}(undef, nbytes)

    for i in 1:nbytes
        bytes[i] = UInt8((value >> (8 * (nbytes - i))) & 0xFF)
    end

    while length(bytes) > 1 && bytes[1] == 0
        bytes = bytes[2:end]
    end

    return bytes
end

function bit_length(x::BigInt)::Int
    return x == 0 ? 0 : floor(Int, log2(x) + 1)
end

function int_to_byte(value::BigInt)::Vector{UInt8}
    return [UInt8(value)]
end

function pad32(value::Vector{UInt8})::Vector{UInt8}
    padding_length = max(32 - length(value), 0)
    padding = fill(UInt8(0), padding_length)
    return vcat(padding, value)
end

function id(prv_key::String)::String
    prv_key_bytes = hex2bytes(prv_key)
    pub = private_key_to_public_key(prv_key_bytes)
    pub_hex = "04" * bytes2hex(pub)  # the prefix "04" denotes that the public key is in uncompressed format
    
    hash_bytes = sha3_256(pub_hex)
    
    return bytes2hex(hash_bytes)
end

function encode_raw_public_key(raw_public_key::Tuple{BigInt, BigInt})::Vector{UInt8}
    left, right = raw_public_key
    return vcat(
        pad32(int_to_big_endian(left)),
        pad32(int_to_big_endian(right))
    )
end

function private_key_to_public_key(private_key_bytes::Vector{UInt8})::Vector{UInt8}
    private_key_as_num = big_endian_to_int(private_key_bytes)

    if private_key_as_num >= N
        throw("Invalid privkey")
    end

    raw_public_key = fast_multiply(G, private_key_as_num)
    public_key_bytes = encode_raw_public_key(raw_public_key)
    return public_key_bytes
end

function hmac(key::Vector{UInt8}, data::Vector{UInt8}, digest_fn::Function)
    return hmac_sha(key, data, digest_fn)
end

function hmac_sha(key::Vector{UInt8}, data::Vector{UInt8}, digest_fn::Function)::Vector{UInt8}
    block_size = 64
    if length(key) > block_size
        key = digest_fn(key)
    end
    key = vcat(key, fill(UInt8(0x00), block_size - length(key)))

    o_key_pad = xor.(key, fill(UInt8(0x5c), block_size))
    i_key_pad = xor.(key, fill(UInt8(0x36), block_size))

    inner = digest_fn(vcat(i_key_pad, data))
    return digest_fn(vcat(o_key_pad, inner))
end

function deterministic_generate_k(msg_hash::Vector{UInt8}, private_key_bytes::Vector{UInt8}, digest_fn::Function=SHA.sha256)::BigInt
    v_0 = fill(UInt8(0x01), 32)
    k_0 = fill(UInt8(0x00), 32)

    k_1 = hmac(k_0, vcat(v_0, UInt8(0x00), private_key_bytes, msg_hash), digest_fn)
    v_1 = hmac(k_1, v_0, digest_fn)
    k_2 = hmac(k_1, vcat(v_1, UInt8(0x01), private_key_bytes, msg_hash), digest_fn)
    v_2 = hmac(k_2, v_1, digest_fn)

    kb = hmac(k_2, v_2, digest_fn)
    k = big_endian_to_int(kb)
    return k
end

function ecdsa_raw_sign(msg_hash::Vector{UInt8}, private_key_bytes::Vector{UInt8})::Tuple{BigInt, BigInt, BigInt}
	z = big_endian_to_int(msg_hash)
    k = deterministic_generate_k(msg_hash, private_key_bytes)
    r, y = fast_multiply(G, k)
	s_raw = mod(inv(k, N) * (z + r * big_endian_to_int(private_key_bytes)), N)
    v = 27 + ((mod(y, 2) ⊻ (if s_raw * 2 < N 0 else 1 end)))
    s = s_raw < N ÷ 2 ? s_raw : N - s_raw
    return v - 27, r, s
end

end
