# Solve a PowerGenome-generated Macro case (simpleCSVinputs format).
#
# Usage:
#
#     julia --project=<macro environment> example_systems/RunMacro.jl [case folder] [options]
#
# `<case folder>` must contain `system_data.json`. That is the Macro case root
# (`<results folder>/<case id>`), not the GenX `Inputs/Inputs_pN` folder. With no
# argument the folder containing this script is used.
#
# Options:
#
#     --algorithm <Monolithic|Myopic>  Solution algorithm to use. Defaults to the
#                                      `SolutionAlgorithm` written by PowerGenome
#                                      (`Monolithic`, i.e. perfect foresight).
#     --periods <n>                    Solve only the first `n` planning periods.
#                                      Defaults to every period in the case.
#     --staging <folder>               Folder for the modified copy of the case.
#                                      Defaults to `<case folder>-<algorithm>-<n>p`.
#
# The options are applied to a staging copy of the case that symlinks the
# read-only `assets`/`system` inputs, so the PowerGenome output is never
# modified. With no options the case is solved in place.
using MacroEnergy
using HiGHS
using JSON3
using JuMP: MOI, objective_value, termination_status
using Logging: @info

const ALGORITHMS = ("Monolithic", "Myopic")

function usage_error(message)
    error(
        message * "\n\nUsage: julia RunMacro.jl [case folder] " *
        "[--algorithm Monolithic|Myopic] [--periods n] [--staging folder]",
    )
end

function parse_args(args)
    options = Dict{String, Any}("case" => nothing, "staging" => nothing)
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg in ("--algorithm", "--periods", "--staging")
            i += 1
            i <= length(args) || usage_error("$(arg) needs a value")
            options[arg[3:end]] = args[i]
        elseif startswith(arg, "-")
            usage_error("Unknown option $(arg)")
        elseif options["case"] === nothing
            options["case"] = arg
        else
            usage_error("Unexpected extra argument $(arg)")
        end
        i += 1
    end

    case_folder = options["case"]
    case_folder = case_folder === nothing ? dirname(abspath(@__FILE__)) : abspath(case_folder)
    isfile(joinpath(case_folder, "system_data.json")) || error(
        "No system_data.json found in $(case_folder). Pass the Macro case folder " *
        "(the run_powergenome results folder for this case).",
    )

    algorithm = get(options, "algorithm", nothing)
    if algorithm !== nothing && !(algorithm in ALGORITHMS)
        usage_error(
            "Unknown algorithm $(algorithm); expected one of $(join(ALGORITHMS, ", ")).",
        )
    end

    periods = get(options, "periods", nothing)
    if periods !== nothing
        parsed = tryparse(Int, periods)
        parsed === nothing && usage_error(
            "--periods must be a positive integer, got $(periods).",
        )
        periods = parsed
        periods > 0 || usage_error("--periods must be a positive integer.")
    end

    return (; case = case_folder, algorithm, periods, staging = get(options, "staging", nothing))
end

# Copy the case into a new folder while symlinking the (read-only) `assets` and
# `system` directories, then apply the algorithm/period overrides to the copy's
# case definition and settings.
function stage_case(config)
    case_folder = config.case
    algorithm = config.algorithm
    periods = config.periods

    case_settings_path = joinpath(case_folder, "settings", "case_settings.json")
    case_settings = JSON3.read(read(case_settings_path, String), Dict{String, Any})
    num_periods = length(case_settings["PeriodLengths"])

    periods === nothing && (periods = num_periods)
    periods <= num_periods || error(
        "Asked for $(periods) periods but $(case_folder) only defines $(num_periods).",
    )
    algorithm === nothing && (algorithm = case_settings["SolutionAlgorithm"])

    staging = config.staging
    if staging === nothing
        label = "$(lowercase(algorithm))-$(periods)p"
        staging = joinpath(dirname(case_folder), "$(basename(case_folder))-$(label)")
    end
    staging = normpath(abspath(staging))
    # Staging deletes its target, so refuse anything at, above, or inside the
    # case folder: `rm` would take live case inputs with it.
    case_root = normpath(abspath(case_folder))
    if startswith(staging * "/", case_root * "/") ||
       startswith(case_root * "/", staging * "/")
        error(
            "Refusing to stage $(algorithm) at $(staging): it overlaps the case " *
            "folder $(case_root), and staging removes its target folder. Pass " *
            "--staging pointing somewhere outside the case folder.",
        )
    end

    rm(staging, recursive = true, force = true)
    mkpath(joinpath(staging, "settings"))
    for input in ("assets", "system")
        symlink(joinpath(case_folder, input), joinpath(staging, input))
    end
    for settings_file in readdir(joinpath(case_folder, "settings"); join = true)
        cp(settings_file, joinpath(staging, "settings", basename(settings_file)); force = true)
    end

    case_settings["PeriodLengths"] = case_settings["PeriodLengths"][1:periods]
    case_settings["SolutionAlgorithm"] = algorithm
    if algorithm == "Myopic"
        # The status check below needs the per-period models, which Macro only
        # retains when asked to return them.
        myopic_settings = get(case_settings, "MyopicSettings", Dict{String, Any}())
        myopic_settings["ReturnModels"] = true
        case_settings["MyopicSettings"] = myopic_settings
    end
    open(joinpath(staging, "settings", "case_settings.json"), "w") do io
        JSON3.pretty(io, case_settings)
    end

    system_data_path = joinpath(case_folder, "system_data.json")
    system_data = JSON3.read(read(system_data_path, String), Dict{String, Any})
    system_data["case"] = system_data["case"][1:periods]
    open(joinpath(staging, "system_data.json"), "w") do io
        JSON3.pretty(io, system_data)
    end

    @info "Staged Macro case" staging period_lengths = case_settings["PeriodLengths"] algorithm
    return staging
end

# Macro's myopic algorithm solves the periods in sequence and returns the models
# instead of a single solution, so optimality is checked period by period.
function check_statuses(solution)
    if solution isa MacroEnergy.MyopicResults
        models = solution.models
        models === nothing && error(
            "Macro did not return the myopic period models, so the solve status " *
            "cannot be checked. Set \"ReturnModels\": true in MyopicSettings.",
        )
        for (period, model) in enumerate(models)
            status = termination_status(model)
            status == MOI.OPTIMAL || error(
                "Macro period $(period) did not solve to optimality " *
                "(termination status: $(status))",
            )
            @info "Macro period solved" period status objective_value = objective_value(model)
        end
    else
        status = termination_status(solution)
        status == MOI.OPTIMAL || error(
            "Macro case did not solve to optimality (termination status: $(status))",
        )
        @info "Macro solve complete" status objective_value = objective_value(solution)
    end
    return nothing
end

config = parse_args(ARGS)
case_path = if config.algorithm === nothing && config.periods === nothing && config.staging === nothing
    config.case
else
    stage_case(config)
end

@info "Solving Macro case" case_path
(case, solution) = run_case(case_path; optimizer = HiGHS.Optimizer)
check_statuses(solution)
