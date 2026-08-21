# Resource groups & profiles — TX-3-zone

This folder (`resource_groups/`) and `resource_profiles/` define the new-build
variable renewable energy (VRE) supply curves and hourly profiles for the
TX-3-zone example.

## Layout

- `solar_group.json` / `onshorewind_group.json` — group definitions pointing at
  the metadata CSV, profile CSV, and site map for each technology
  (`technology`: `utilitypv` / `landbasedwind`).
- `solar_lcoe_tx_3_zone.csv` / `onshorewind_lcoe_tx_3_zone.csv` — per-site
  metadata: `cpa_id`, `region` (ReEDS BA p60–p65, p67), `capacity_mw`, `cf`,
  `lcoe`, `interconnect_annuity`, `interconnect_capex_mw`, `resource_annuity`,
  `resource_fom`. 70 sites per technology across the 7 ERCOT BAs. Values were
  derived from the EI_PJM / WECC `resource_groups/*lcoe_ReEDS.csv` metadata
  (which carry lcoe/resource_annuity/resource_fom/interconnect_capex_mw for all
  134 ReEDS BAs including ERCOT).
- `resource_profiles/solar_profiles_tx_3_zone.csv` /
  `onshorewind_profiles_tx_3_zone.csv` — tidy hourly profiles
  (`site_id, time_index, value, weather_year`), 240 hours at weather year 2012
  per site, values normalized to [0, 1].
- `resource_profiles/*_site_map_tx_3_zone.csv` — `cpa_id` → profile site
  mapping (1:1). Site IDs use the group-style names
  `<BA>_<tech>_g<nn>` (e.g. `p60_solar_g01`), consistent across the lcoe
  metadata, profile `site_id` column, and site map (10 sites per BA × 7 BAs
  = 70).

## ⚠️ Synthetic profile stand-ins

The **hourly profiles are synthetic stand-ins**, not measured resource output.
PowerGenome's WECC/EI_PJM resource-group JSONs point at missing multi-GB
rev-profile parquet files (a `path` column in the source metadata); those files
are not available in the data cache. To keep this example runnable, we generated
plausible tidy profiles:

- **Solar**: diurnal daylight shape (zero at night, peaking at midday), scaled
  per-site with a small phase/shape perturbation so each site differs.
- **Wind**: a shared 240-hour correlated wind shape with per-site amplitude
  scaling (so sites differ in capacity factor while staying correlated, a
  realistic property of regional wind).

These are *normalized* shapes — the metadata `cf`/`capacity_mw` columns drive
absolute output. They are adequate for end-to-end testing, capacity planning,
and as a proof that the v0.8 resource-group pipeline works.

### Replacing with real profiles

To use real profiles: replace the two profile CSVs (keep columns
`site_id, time_index, value, weather_year` and the same 240-hour time index and
weather_year 2012, or adjust them together with the rest of the example's
time index) and the site maps if site IDs change. No other settings change.

## Hourly time index

All profiles share the example-wide 240-hour index (weather year 2012, 240 hours
evenly spaced across the year), consistent with `data/reeds_load_tx_3_zone.csv` and
`data/distributed_profiles_tx_3_zone.csv`.
