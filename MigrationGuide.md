# Migration Guide: Colonies.jl v1.9.6

This guide covers breaking changes when upgrading to the v1.9.6-compatible version of Colonies.jl.

## Overview

The SDK now uses a simplified `ProcessResult` struct instead of the full `Process` struct for return values from `submit`, `assign`, `getprocess`, `getprocesses`, and `addchild` functions. This change was made to handle complex nested JSON responses from the server more reliably.

## Breaking Changes

### 1. Return Type Changed

Functions that previously returned `Process` now return `ProcessResult`:

```julia
# Affected functions:
Colonies.submit()
Colonies.assign()
Colonies.getprocess()
Colonies.getprocesses()
Colonies.addchild()
```

### 2. ProcessResult vs Process

**Old `Process` struct fields:**
- `processid`, `initiatorid`, `initiatorname`, `assignedexecutorid`
- `isassigned`, `state`, `prioritytime`
- `submissiontime`, `starttime`, `endtime`, `waitdeadline`, `execdeadline`
- `retries`, `attributes`, `spec` (FunctionSpec struct)
- `waitforparents`, `parents`, `children`, `processgraphid`
- `in`, `out`, `errors`

**New `ProcessResult` struct fields:**
- `processid::String`
- `state::Int`
- `spec::Dict{String, Any}`
- `output::Vector{Any}`
- `errors::Vector{Any}`

### 3. Accessing spec Fields

The `spec` field changed from a `FunctionSpec` struct to a `Dict{String, Any}`:

```julia
# Before (v1.9.5 and earlier)
process = Colonies.submit(client, funcspec, prvkey)
funcname = process.spec.funcname
colonyname = process.spec.conditions.colonyname

# After (v1.9.6)
process = Colonies.submit(client, funcspec, prvkey)
funcname = process.spec["funcname"]
colonyname = process.spec["conditions"]["colonyname"]
```

### 4. Output Field Renamed

The `out` field was renamed to `output`:

```julia
# Before
results = process.out

# After
results = process.output
```

### 5. Removed Fields

The following fields are no longer available on the result:
- `initiatorid`, `initiatorname`
- `assignedexecutorid`, `isassigned`
- `prioritytime`, `submissiontime`, `starttime`, `endtime`
- `waitdeadline`, `execdeadline`
- `retries`, `attributes`
- `waitforparents`, `parents`, `children`
- `processgraphid`, `in`

If you need these fields, use `getprocess()` and access them from the raw spec Dict, or submit a feature request.

## Migration Examples

### Example 1: Submitting and Checking State

```julia
# Before
process = Colonies.submit(client, funcspec, prvkey)
if process.state == Colonies.WAITING
    println("Process $(process.processid) is waiting")
end

# After (unchanged - these fields still exist)
process = Colonies.submit(client, funcspec, prvkey)
if process.state == Colonies.WAITING
    println("Process $(process.processid) is waiting")
end
```

### Example 2: Accessing Function Name from Result

```julia
# Before
process = Colonies.getprocess(client, processid, prvkey)
println("Function: $(process.spec.funcname)")

# After
process = Colonies.getprocess(client, processid, prvkey)
println("Function: $(process.spec["funcname"])")
```

### Example 3: Checking Executor Type

```julia
# Before
process = Colonies.assign(client, colonyname, timeout, prvkey)
if process.spec.conditions.executortype == "my-executor"
    # handle
end

# After
process = Colonies.assign(client, colonyname, timeout, prvkey)
if process.spec["conditions"]["executortype"] == "my-executor"
    # handle
end
```

### Example 4: Getting Output

```julia
# Before
process = Colonies.getprocess(client, processid, prvkey)
for result in process.out
    println(result)
end

# After
process = Colonies.getprocess(client, processid, prvkey)
for result in process.output
    println(result)
end
```

## Unchanged Functionality

The following functions and their usage remain unchanged:
- `Colonies.addcolony()`
- `Colonies.addexecutor()`
- `Colonies.approveexecutor()`
- `Colonies.addfunction()`
- `Colonies.addattribute()`
- `Colonies.closeprocess()`
- `Colonies.failprocess()`
- `Colonies.addlog()`
- `Colonies.getlogs()`
- `Colonies.wait()`

Input types (`FunctionSpec`, `Conditions`, `Executor`, etc.) remain unchanged.

## Helper Function for Dict Access

If you frequently access nested spec fields, consider a helper:

```julia
function get_spec_field(process::Colonies.ProcessResult, keys...)
    result = process.spec
    for key in keys
        result = get(result, key, nothing)
        if result === nothing
            return nothing
        end
    end
    return result
end

# Usage
funcname = get_spec_field(process, "funcname")
executortype = get_spec_field(process, "conditions", "executortype")
```

## Questions or Issues

If you encounter issues during migration, please open an issue at:
https://github.com/colonyos/Colonies.jl/issues
