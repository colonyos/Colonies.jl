using Test
using Colonies

# ============================================================================
# Conditions Tests
# ============================================================================

function test_conditions_with_locationname()
    cond = Colonies.Conditions(
        colonyname = "test-colony",
        executornames = ["executor1"],
        executortype = "test-type",
        locationname = "datacenter-1",
        dependencies = String[],
        nodes = 2,
        cpu = "2000m",
        processes = 4,
        processespernode = 2,
        mem = "4Gi",
        storage = "10Gi",
        gpu = Colonies.GPU("nvidia-a100", "40Gi", 1, 1),
        walltime = 3600
    )
    cond.locationname == "datacenter-1" && cond.nodes == 2
end

function test_conditions_default_locationname()
    cond = Colonies.Conditions("test-colony", String[], "test-type", String[])
    cond.locationname == ""
end

# ============================================================================
# FunctionSpec Tests
# ============================================================================

function test_functionspec_with_channels()
    cond = Colonies.Conditions("test-colony", String[], "test-type", String[])
    # Use the full constructor with correct types
    spec = Colonies.FunctionSpec(
        "node1",                                    # nodename
        "test-func",                                # funcname
        Any["arg1", 123, true],                     # args
        Dict{Any, Any}("key1" => "value1"),         # kwargs
        1,                                          # priority
        60,                                         # maxwaittime
        300,                                        # maxexectime
        3,                                          # maxretries
        cond,                                       # conditions
        "test-label",                               # label
        Colonies.Filesystem(),                      # fs
        Dict{Any, Any}("VAR1" => "val1"),           # env
        ["channel1", "channel2"]                    # channels
    )
    spec.channels == ["channel1", "channel2"]
end

function test_functionspec_default_channels()
    cond = Colonies.Conditions("test-colony", String[], "test-type", String[])
    spec = Colonies.FunctionSpec("node1", "test-func", String[], 1, 60, 300, 3, cond, "label")
    spec.channels == String[]
end

# ============================================================================
# Process Tests
# ============================================================================

function test_process_in_out_any_type()
    cond = Colonies.Conditions("test-colony", String[], "test-type", String[])
    spec = Colonies.FunctionSpec("node1", "test-func", String[], 1, 60, 300, 3, cond, "label")

    # Create a process with mixed-type input/output
    proc = Colonies.Process(
        processid = "test-id",
        initiatorid = "initiator-id",
        initiatorname = "initiator-name",
        assignedexecutorid = "",
        isassigned = false,
        state = Colonies.WAITING,
        prioritytime = UInt64(0),
        submissiontime = "",
        starttime = "",
        endtime = "",
        waitdeadline = "",
        execdeadline = "",
        retries = UInt16(0),
        attributes = Colonies.Attribute[],
        spec = spec,
        waitforparents = false,
        parents = String[],
        children = String[],
        processgraphid = "",
        in = Any["string-input", 123, Dict("key" => "value")],
        out = Any["result", 456, true],
        errors = String[]
    )

    # Verify mixed types are preserved
    proc.in[1] == "string-input" &&
    proc.in[2] == 123 &&
    proc.out[1] == "result" &&
    proc.out[2] == 456 &&
    proc.out[3] == true
end

function test_process_empty_in_out()
    cond = Colonies.Conditions("test-colony", String[], "test-type", String[])
    spec = Colonies.FunctionSpec("node1", "test-func", String[], 1, 60, 300, 3, cond, "label")

    proc = Colonies.Process(
        processid = "test-id",
        initiatorid = "initiator-id",
        initiatorname = "initiator-name",
        assignedexecutorid = "",
        isassigned = false,
        state = Colonies.WAITING,
        prioritytime = UInt64(0),
        submissiontime = "",
        starttime = "",
        endtime = "",
        waitdeadline = "",
        execdeadline = "",
        retries = UInt16(0),
        attributes = Colonies.Attribute[],
        spec = spec,
        waitforparents = false
    )

    isempty(proc.in) && isempty(proc.out)
end

# ============================================================================
# GPU Tests
# ============================================================================

function test_gpu_struct()
    gpu = Colonies.GPU("nvidia-a100", "80Gi", 4, 2)
    gpu.name == "nvidia-a100" && gpu.mem == "80Gi" && gpu.count == 4 && gpu.nodecount == 2
end

function test_gpu_default_nodecount()
    gpu = Colonies.GPU("nvidia-v100", "32Gi", 2)
    gpu.nodecount == 0
end

# ============================================================================
# ProcessResult Tests
# ============================================================================

function test_processresult_struct()
    result = Colonies.ProcessResult(
        processid = "proc-123",
        state = Colonies.SUCCESS,
        spec = Dict{String, Any}("funcname" => "test"),
        input = Any["input1", 123],
        output = Any["result1", 42],
        errors = Any[]
    )
    result.processid == "proc-123" &&
    result.state == Colonies.SUCCESS &&
    result.input == Any["input1", 123] &&
    result.output == Any["result1", 42]
end

# ============================================================================
# ChannelEntry Tests
# ============================================================================

function test_channelentry_struct()
    entry = Colonies.ChannelEntry(
        sequence = 1,
        data = "test-data",
        msgtype = "data",
        inreplyto = 0
    )
    entry.sequence == 1 && entry.data == "test-data" && entry.msgtype == "data"
end

# ============================================================================
# Run Tests
# ============================================================================

@testset "Core Struct Tests" begin
    # Conditions tests
    @test test_conditions_with_locationname()
    @test test_conditions_default_locationname()

    # FunctionSpec tests
    @test test_functionspec_with_channels()
    @test test_functionspec_default_channels()

    # Process tests
    @test test_process_in_out_any_type()
    @test test_process_empty_in_out()

    # GPU tests
    @test test_gpu_struct()
    @test test_gpu_default_nodecount()

    # ProcessResult tests
    @test test_processresult_struct()

    # ChannelEntry tests
    @test test_channelentry_struct()
end
