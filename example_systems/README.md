# Example systems

Ready-to-run PowerGenome example systems. Each folder is a self-contained
`example_systems/<system>` directory with `settings/` (v0.8 split-format YAML
settings, including `data.yml`), slimmed `data/` tables, `resource_groups/` and
`resource_profiles/` for new-build VRE, and `extra_inputs/`.

All examples target the v0.8 settings layout on PowerGenome **`main`** (`v0.8.0-beta`
and later; the CI workflow runs against `main`).

## TX-3-zone (Texas ERCOT, 3 zones)

Replaces the former `CONUS-3-zone` example (US-wide system keyed by IPM regions).
This example models ERCOT at a 3-zone resolution using **ReEDS balancing areas
(BA)** as base geography.

* Model regions: `TX1`, `TX2`, `TX3`
* Region aggregations (ReEDS BAs):
  * `TX1` = [p60, p61, p62]
  * `TX2` = [p63, p64]
  * `TX3` = [p65, p67]
* Model years: 2030, 2045 (model_first_planning_year 2025, 2031)
* Weather year: 2012, downsampled to a shared **240-hour time index** (10 days,
  ~1 sample per 36.5 h, all seasons + all hours-of-day) so GenX solves quickly
  with HiGHS
* New-build VRE: site-level supply curves + hourly profiles for utility PV and
  onshore wind (synthetic tidy profiles as stand-ins; see `resource_groups/`)
* Existing VRE:
  `resource_groups/existing_resource_groups/regional_solar_photovoltaic_True.json`
  and `regional_wind_True.json` give the existing utility PV (40.7 GW) and
  onshore wind (36.7 GW) capacity the same site-level profiles as new build
  (TX1 alone holds 12.3 GW PV and 21.0 GW wind). PowerGenome requires profiles
  for existing VRE groups unless the un-profiled capacity stays under
  `existing_resource_profile_fallback_max_demand_fraction` (0.5% of mean demand),
  which that capacity does not in any model region. Existing groups must set
  `"existing": true` (matched separately from the new-build groups for the same
  technology) and read a metadata table keyed by `id`
  (`existing_solar_metadata.csv` / `existing_onshorewind_metadata.csv`, derived
  from the new-build supply curves so `id` lines up with the profile `site_id`s).
* No policy (Texas has no RPS in the available regional files); the
  `emission_policies.csv` in `extra_inputs/` is a no-policy placeholder.

Run it:

```bash
run_powergenome --settings_file example_systems/TX-3-zone/settings --results_folder <output>

# Also write a Macro case (simpleCSVinputs) and solve it with MacroEnergy.jl
run_powergenome --settings_file example_systems/TX-3-zone/settings --results_folder <output> --macro
julia --project=<macro environment> example_systems/RunMacro.jl <output>/base
```

`RunMacro.jl` also takes `--algorithm Monolithic|Myopic` and `--periods N`, so the
same case can be solved one period at a time or myopically, e.g.
`--algorithm Myopic --periods 2`. Narrowed runs solve a staged copy of the case
(`base-myopic-2p` and similar), which leaves the PowerGenome output untouched.
See the "Solving with Macro" section of the [main README](../README.md) for the
pinned `MacroEnergy` version, the environment setup, and the discount-rate
(`macro_discount_rate` / GenX multistage `WACC`) behavior.

Two planning periods are modelled (2025-2030 and 2031-2045). They are solved

* with GenX as a single-stage case for the first period (`MultiStage: 0`), as a
  myopic multistage solve of both periods, and as multistage perfect foresight
  (dual dynamic programming, `Myopic: 0`), using
  `genx_settings/multi_stage_settings.yml` (`StageLengths: [6, 15]`,
  `WACC: 0.045`), and
* with Macro for the first period only, myopically, and in perfect foresight
  (`Monolithic`).

That matrix is what the CI workflow runs.

### Network costs placeholder

The transmission cost table (`data/network_costs_tx_3_zone.csv`) currently holds
**derived placeholder values** keyed to TX1/TX2/TX3. See
`data/network_costs_tx_3_zone_PLACEHOLDER.md` for the required schema and where a
user-provided file should go.

## CA_AZ (California + Arizona, 2 zones)

A smaller 2-zone example covering California and Arizona, built from **ReEDS
balancing areas** and formatted for the v0.8 settings layout.

* Model regions: `CA`, `AZ`
* Region aggregations (ReEDS BAs):
  * `CA` = [p8, p9, p10, p11]
  * `AZ` = [p27, p28, p29, p30]
* Model years: 2030, 2045 (model_first_planning_year 2025, 2031)
* Weather year: 2012, downsampled to a shared **240-hour time index** (Jan 1–10,
  consecutive hours 1..240) so GenX solves quickly with HiGHS
* New-build VRE: 16-site supply curves + hourly profiles each for utility PV and
  onshore wind (synthetic tidy profiles as stand-ins; see `resource_groups/`)
* Policy: California ESR_1 0.571 / ESR_2 0.952 and Arizona ESR_1 0.087 in 2045
  (see `extra_inputs/emission_policies.csv`)

The new-build VRE hourly profiles in both examples are **synthetic stand-ins**
(solar = daylight cosine, wind = correlated diurnal shapes) because the source
multi-GB ReEDS `*_rev_profiles` parquets are not mirrored in PowerGenome-data.
They follow the exact tidy schema (`site_id, time_index, value, weather_year`) so
real profiles can be dropped in later. See each example's `resource_groups/` and
`data/README.md` for details.
