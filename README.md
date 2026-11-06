# PowerGenome-examples
Example setups to use with PowerGenome

This repository contains ready-to-run example systems and supporting files
(GenX solver settings, Julia runner scripts) for PowerGenome.

## Example systems

See [example_systems/README.md](example_systems/README.md) for details. Examples
include:

* **TX-3-zone** — a Texas ERCOT example with 3 model regions (TX1, TX2, TX3)
  built from 7 ReEDS balancing areas (p60–p65, p67). This replaces the former
  `CONUS-3-zone` example (a US-wide system keyed by IPM regions) and is formatted
  for the v0.8 settings layout on PowerGenome `main`.
* **CA_AZ** — a 2-zone California + Arizona example.

## GenX solver settings

`example_systems/genx_settings/` contains GenX solver settings (`genx_settings.yml`
and solver-specific files for cbc, clp, cplex, gurobi, highs, etc.).

## Running a case

```bash
# Build model inputs from a system's settings
run_powergenome --settings_file example_systems/TX-3-zone/settings --results_folder <output>

# Solve with GenX (Julia)
julia example_systems/Run.jl

# ... or build GenX and Macro inputs in the same run, then solve with Macro
run_powergenome --settings_file example_systems/TX-3-zone/settings --results_folder <output> --macro
julia --project=<macro environment> example_systems/RunMacro.jl <output>/<case id>
```

## Solving with Macro

[Macro](https://github.com/macroenergy/MacroEnergy.jl) (MacroEnergy.jl) is an
energy system optimization model. PowerGenome writes a Macro case in
the `simpleCSVinputs` format alongside the GenX inputs when it runs with
`--macro` (or `macro_output: true` in the settings); pass `--no-genx` instead to
write only the Macro case. The Macro case root is `<results_folder>/<case id>`
and contains `system_data.json`, `settings/`, `system/` and `assets/`.

`example_systems/RunMacro.jl` solves such a case (every planning period, with
HiGHS) and exits non-zero unless the model reaches optimality:

```bash
mkdir -p macro-env
julia --project=macro-env -e 'using Pkg; Pkg.add([
    PackageSpec(name="MacroEnergy", version="0.2.5"),
    PackageSpec(name="HiGHS"),
    PackageSpec(name="JuMP"),
])'
julia --project=macro-env example_systems/RunMacro.jl <results_folder>/<case id>
```

`MacroEnergy` is pinned to **v0.2.5** — the latest registered release, and the
version that matches the case format PowerGenome writes. Results are
written to `<case id>/results_NNN/results_period_N/`. JuMP is installed
alongside MacroEnergy because MacroEnergy does not re-export the solver-status
helpers that `RunMacro.jl` uses to check the termination status.

[`.github/workflows/test_example_system.yml`](.github/workflows/test_example_system.yml)
runs this whole pipeline for TX-3-zone: PowerGenome builds GenX and Macro inputs,
GenX solves both planning periods, then Macro solves the generated case.
