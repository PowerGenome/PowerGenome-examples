# CA_AZ slimmed data files (PowerGenome v0.8, 2-zone CA + AZ, ReEDS BAs)

These files are the PowerGenome v0.8 input tables referenced by `settings/data.yml`.
Geography: the 8 ReEDS balancing areas CA = p8-p11, AZ = p27-p30, aggregated to
model regions `[CA, AZ]`. All files are CSV, each well under 1 MB.

## Time grid (shared across ALL time-series files)
- Single weather year **2012**, non-leap 8760h calendar.
- A shared **240-hour (10-day)** index is used by every time-series file:
  the first 240 consecutive hours of 2012 (Jan 1-10), `time_index` = 1..240.
  This preserves 10 full diurnal cycles, is identical across all regions/files,
  and keeps the GenX build small so HiGHS solves quickly.
- `time_clustering.yml` sets `reduce_time_domain: false` (no further clustering).

## Files
| File | Source | Notes |
|---|---|---|
| `generators.csv` | PowerGenome-data `data/reeds_generators_transformed.csv` | Existing generators for the 8 BAs only (3,242 rows) |
| `plant_region_map.csv` | `data/plant_region_map.csv` | plant_id -> BA for 8 BAs (1,908 rows) |
| `technology_heat_rates.csv` | `data/technology_heat_rates_nrelatb.csv` | data_year 2024 only (2,104 rows) |
| `technology_costs.csv` | `data/technology_costs_atb.parquet` | ATB data_year 2024, cost_case Moderate, financial_case Market, all techs/params in `new_resources` (1,088 rows) |
| `operational_constraints.csv` | `data/operational_constraints_reeds.csv` | 8 BAs (116 rows) |
| `transmission_capacity.csv` | `data/transmission_capacity_reeds.csv` | firm_ttc_mw among the 8 BAs (9 rows) |
| `network_costs.csv` | `data/network_costs_ReEDS.csv` | KEYED BY MODEL REGIONS CA/AZ (aggregated CA-CA, AZ-AZ, CA-AZ), dollar_year 2018 |
| `fuel_prices.csv` | `data/fuel_prices.parquet` | per-BA prices, fuel_data_year 2025, dollar_year 2024, years 2024-2050 (1,728 rows) |
| `cpi_data.csv` | `data/cpi_data.csv` | CPI deflators for dollar-year conversion |
| `regional_cost_multipliers.csv` | `data/regional_cost_multipliers.csv` | 8 BAs (304 rows) |
| `demand_load.csv` | `data/reeds_load_transformed.parquet` | 8 BAs x {2030, 2045} x 240h x weather_year 2012, scenario IRA_low (3,840 rows) |
| `distributed_capacity.csv` | `data/distributed_capacity.parquet` | 8 BAs, years 2024-2050 (112 rows) |
| `distributed_profiles.csv` | `data/distributed_profiles.parquet` | 8 BAs x 240h (1,920 rows) |
| `resource_groups/*_metadata.csv`, `*_profiles.csv`, `*.json` | WECC/resource_groups + synthetic | New-build VRE clusters (see below) |

## New-build VRE resource groups (resource_groups/)
- `solar_group.json`, `onshorewind_group.json`: new-build UtilityPV / LandbasedWind
  clusters, one per site (cpa_id) in the 8 BAs (16 solar + 16 wind). Metadata carries
  `interconnect_capex_mw` (from PowerGenome-data WECC metadata); LCOE/annuity/FOM.
- `existing_resource_groups/`: existing solar (8 BAs) and onshore wind (5 BAs) clusters.
- **Profiles are SYNTHETIC STAND-INS.** The PowerGenome-data resource-group `path`
  column points at multi-GB raw profile parquets that are excluded from this repo.
  Instead, tidy hourly profiles (site_id, time_index 1..240, value, weather_year 2012)
  are generated per site with physically plausible shapes (solar: summer-weighted
  daily cosine peak ~2pm; wind: walk with night-favoring diurnal), phase-aligned to the
  shared time index. They are placeholders for demonstration; swap in real profiles by
  replacing the `*_profiles.csv` files (keep the same site_id/time_index schema).

## Rebuild
Regenerate every file deterministically with
`/Users/gs5183/.copilot/session-state/2f901050-94c1-4546-96ac-d24b3a51a9ce/files/build_ca_az_data.py`
(then move the four `*_profiles.csv` / `*_metadata.csv` pairs from `data/` into
`resource_groups/` and `resource_groups/existing_resource_groups/`).
