# Solve a PowerGenome-generated Macro case (simpleCSVinputs format).
#
# Usage:
#
#     julia --project=<macro environment> example_systems/RunMacro.jl <case folder>
#
# `<case folder>` must contain `system_data.json`. That is the Macro case root
# (`<results folder>/<case id>`), not the GenX `Inputs/Inputs_pN` folder. With no
# argument the folder containing this script is used.
using MacroEnergy
using HiGHS
using JuMP: MOI, objective_value, termination_status

case_path = isempty(ARGS) ? dirname(abspath(@__FILE__)) : abspath(first(ARGS))

if !isfile(joinpath(case_path, "system_data.json"))
    error(
        "No system_data.json found in $(case_path). Pass the Macro case folder " *
        "(the run_powergenome results folder for this case).",
    )
end

@info "Solving Macro case" case_path
(case, solution) = run_case(case_path; optimizer=HiGHS.Optimizer)

status = termination_status(solution)
if status != MOI.OPTIMAL
    error("Macro case did not solve to optimality (termination status: $(status))")
end

@info "Macro solve complete" status objective_value = objective_value(solution)
