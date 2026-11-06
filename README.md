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
  for PowerGenome v0.8.0-beta.
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
```
