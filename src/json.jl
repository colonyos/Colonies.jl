using JSON
using StructMapping

function marshaljson(object::Any)
    return JSON.json(object)
end

function unmarshaljson(jsonstr::String, structtarget::Any)
    try 
      res = JSON.parse(jsonstr)
      if typeof(res) <: AbstractArray
        cleaned_res = similar(res)
        s = eltype(structtarget)[]
        for i in eachindex(res)
          cleaned_res[i] = rm_nothing(res[i])
          push!(s, StructMapping.convertdict(eltype(structtarget), cleaned_res[i]))
        end
      else
        cleaned_res = rm_nothing(res)
        s = StructMapping.convertdict(structtarget, cleaned_res)
      end
      return s
    catch err
      @error err
    end
end

function unmarshaljson2dict(jsonstr::String)
    try 
      JSON.parse(jsonstr)
    catch err
      @error err
    end
end

function rm_nothing(dict::Dict)
    res_dict = Dict()
    for k in keys(dict)
        if typeof(dict[k]) <: Dict
            res_dict[k] = deepcopy(rm_nothing(dict[k]))
        elseif dict[k] !== nothing
            res_dict[k] = dict[k]
        end
    end
    res_dict
end
