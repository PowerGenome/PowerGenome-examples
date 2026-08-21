# Slimmed data tables — TX-3-zone

All data-table files referenced by `settings/data.yml` live in this folder.
They are slimmed from the full PowerGenome-data cache to the 7 ERCOT ReEDS
balancing areas used by this example (p60, p61, p62, p63, p64, p65, p67) and,
for timeseries, downsampled to a shared 876-hour index (weather year 2012).
All files are CSV (or the small ATB CO2/heat-rate/cpi tables below) and each is
well under a few MB.

| File | Contents |
| --- | --- |
| `reeds_generators_tx_3_zone.csv` | Existing + new-build generators for the 7 BAs (1,911 rows) |
| `plant_region_map_tx_3_zone.csv` | Generator → BA region mapping (839 rows) |
| `reeds_load_tx_3_zone.csv` | Hourly load, 7 BAs × 876 h × 2 model years (12,264 rows) |
| `fuel_prices_tx_3_zone.csv` | Per-BA fuel prices, 7 BAs × 4 fuels × 27 years (756 rows) |
| `technology_costs_atb_tx_3_zone.csv` | **Slimmed NREL ATB**: technologies in `new_resources`, cost_case=Moderate, financial_case=Market (24,655 rows, ~2 MB) |
| `technology_heat_rates_nrelatb.csv` | Fuel → heat-rate table (as-in source) |
| `transmission_capacity_tx_3_zone.csv` | Inter-BA firm/total transfer capacity (11 BA pairs) |
| `network_costs_tx_3_zone.csv` | Zone-pair interconnection costs, keyed by **model** regions TX1/TX2/TX3 (3 rows). See `network_costs_tx_3_zone_PLACEHOLDER.md` |
| `regional_cost_multipliers_tx_3_zone.csv` | Regional cost multipliers for the 7 BAs (266 rows) |
| `operational_constraints_tx_3_zone.csv` | Generator operational constraints (region=all expands to model regions) |
| `reserve_margins_tx_3_zone.csv` | Planning reserve margin per model region (182 rows) |
| `distributed_capacity_tx_3_zone.csv` | Existing distributed PV capacity per BA (98 rows) |
| `distributed_profiles_tx_3_zone.csv` | Distributed PV hourly profiles, 7 BAs × 876 h (6,132 rows) |
| `cpi_data.csv` | CPI index for dollar-year conversions (as-in source) |

## Re-deriving the slimmed files

The slimming script that produced these files from
`/Users/gs5183/Documents/github/PowerGenome-data/data/` lives in the session
artifacts (`slim_tx_data.py`); the exact filter/aggregation rules are
documented there. Key rules:

- **Regions**: keep only rows whose region column ∈ {p60, p61, p62, p63, p64,
  p65, p67}.
- **Timeseries**: keep only the 876-hour subset shared by every profile
  (weather year 2012), then merge with `weather_year=2012` column.
- **ATB costs**: any change to a new-build technology, cost case, or financial
  case in `settings/resources.yml` requires re-slimming `technology_costs_atb`
  from the full parquet (`resources` filter:
  `data_year` unrestricted, `cost_case=Moderate`,
  `financial_case=Market`, `technology ∈ <new_resources technologies>`,
  `cap_recovery_years` unrestricted). Re-run:
  ```python
  import pandas as pd
  df = pd.read_parquet("<PowerGenome-data>/data/technology_costs_atb.parquet")
  keep = df[(df.technology.isin(TECHS)) &
            (df.cost_case == "Moderate") & (df.financial_case == "Market")]
  keep.to_csv("technology_costs_atb_tx_3_zone.csv", index=False)
  ```
  where `TECHS` is the technology list from `new_resources`.
