# Example systems

Ready-to-run PowerGenome example systems. Each folder is a self-contained
`example_systems/<system>` directory with `settings/` (v0.8 split-format YAML
settings, including `data.yml`), slimmed `data/` tables, `resource_groups/` and
`resource_profiles/` for new-build VRE, and `extra_inputs/`.

All examples target PowerGenome **v0.8.0-beta**.

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
* No policy (Texas has no RPS in the available regional files); the
  `emission_policies.csv` in `extra_inputs/` is a no-policy placeholder.

Run it:

```bash
run_powergenome --settings_file example_systems/TX-3-zone/settings --results_folder <output>
```

### Network costs placeholder

The transmission cost table (`data/network_costs_tx_3_zone.csv`) currently holds
**derived placeholder values** keyed to TX1/TX2/TX3. See
`data/network_costs_tx_3_zone_PLACEHOLDER.md` for the required schema and where a
user-provided file should go.

## CA_AZ (California + Arizona, 2 zones)

A smaller 2-zone example covering California and Arizona, built from **ReEDS
balancing areas** and formatted for PowerGenome v0.8.0-beta.

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
