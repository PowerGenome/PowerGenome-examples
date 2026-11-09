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

`example_systems/RunMacro.jl` solves such a case with HiGHS and exits non-zero
unless every planning period it solves reaches optimality:

```bash
mkdir -p macro-env
julia --project=macro-env -e 'using Pkg; Pkg.add([
    PackageSpec(name="MacroEnergy", version="0.2.5"),
    PackageSpec(name="HiGHS"),
    PackageSpec(name="JuMP"),
    PackageSpec(name="JSON3"),
])'

# every planning period, perfect foresight (Macro's Monolithic algorithm)
julia --project=macro-env example_systems/RunMacro.jl <results_folder>/<case id>

# the first planning period only
julia --project=macro-env example_systems/RunMacro.jl <results_folder>/<case id> --periods 1

# both planning periods, solved one after the other (myopic)
julia --project=macro-env example_systems/RunMacro.jl <results_folder>/<case id> --algorithm Myopic --periods 2
```

Options are `[case folder] [--algorithm Monolithic|Myopic] [--periods N]` and
`[--staging FOLDER]`. When `--algorithm` or `--periods` narrows the run,
`RunMacro.jl` solves a staged copy of the case at `<case folder>-<algorithm>-<N>p`
instead of the case itself: `assets/` and `system/` are symlinked, and
`settings/case_settings.json` plus `system_data.json` are rewritten for the
requested periods and algorithm. That keeps each configuration's `results_NNN/`
separate and leaves the PowerGenome output untouched.

`MacroEnergy` is pinned to **v0.2.5** — the latest registered release, and the
version that matches the case format PowerGenome writes. Results are
written to `<case folder>/results_NNN/results_period_N/`. JuMP is installed
alongside MacroEnergy because MacroEnergy does not re-export the solver-status
helpers that `RunMacro.jl` uses to check the termination status; JSON3 is used to
rewrite the staged case settings. For `Monolithic` runs Macro reports a single
termination status per case, while a `Myopic` run returns one model per period —
`RunMacro.jl` enables `ReturnModels` and checks every one of them.

### Discount rate

Both models discount costs across the planning periods, so the two rates should
agree:

* **Macro:** MacroEnergy's own default `DiscountRate` is `0.0`, but PowerGenome
  always writes one: `macro_discount_rate` (default `0.045`) becomes
  `DiscountRate` in `<case id>/settings/case_settings.json`. Add
  `macro_discount_rate` to the settings to change it.
* **GenX multistage:** `WACC` in
  `example_systems/genx_settings/multi_stage_settings.yml` is the rate GenX
  discounts *between stages* with (`0.045` here, matching PowerGenome's Macro
  default; GenX's own multistage default is also `0.045`). Per-resource capital
  costs use each resource's own `WACC` from `Resource_multistage_data.csv`, which
  PowerGenome fills from the same `wacc_real` values as the single-stage inputs.
  Existing resources carry `WACC: 0.0`, which is fine because they have no new
  investment cost.

### What the CI runs

[`.github/workflows/test_example_system.yml`](.github/workflows/test_example_system.yml)
runs the whole pipeline for TX-3-zone and solves the generated case with both
models in several configurations, so changes to the example or to PowerGenome's
writers show up as a failing solve:

| Model | Configuration | Case folder |
|---|---|---|
| GenX | one period (2030), single stage | `<results>/base/Inputs/Inputs_p1` |
| GenX | both periods, myopic multistage | `<results>/genx-myopic` |
| GenX | both periods, multistage perfect foresight (dual dynamic programming) | `<results>/genx-foresight` |
| Macro | first period only | `<results>/base-monolithic-1p` |
| Macro | both periods, myopic | `<results>/base-myopic-2p` |
| Macro | both periods, perfect foresight (`Monolithic`) | `<results>/base-monolithic-2p` |

The GenX multistage steps stage their own case folders next to the PowerGenome
output because GenX's multistage runner reads `inputs/inputs_pN` (lowercase) while
PowerGenome writes `Inputs/Inputs_pN`; the staging step links the two and rewrites
`NumStages`/`StageLengths` from the planning periods PowerGenome actually solved,
so the shared `multi_stage_settings.yml` cannot drift from the example.
