# Network cost file placeholder — `network_costs_tx_3_zone.csv`

**Drop your real file at exactly this path** (same filename):

```
example_systems/TX-3-zone/data/network_costs_tx_3_zone.csv
```

`settings/data.yml` references it as `transmission_cost_table: network_costs_tx_3_zone.csv`.
It is loaded by `powergenome/external_data.py` (`_read_transmission_costs`) and mapped to
GenX `Line_Reinforcement_Cost_per_MWyr`.

## Required columns (headers must match exactly)

| column                          | type   | notes                                              |
|---------------------------------|--------|----------------------------------------------------|
| `start_region`                  | string | One of `TX1`, `TX2`, `TX3` (mapped to z1/z2/z3)    |
| `dest_region`                   | string | One of `TX1`, `TX2`, `TX3`, != start               |
| `total_interconnect_annuity_mw` | float  | $/MW-yr annuity, at `dollar_year`                  |
| `total_interconnect_cost_mw`    | float  | $/MW capital cost, at `dollar_year`                |
| `dollar_year`                   | int    | Year the cost columns are denominated in           |

- Rows whose `start_region`/`dest_region` are NOT model regions are silently dropped
  (`dropna` on the zone map) — so a full BA-level file (p60..p65,p67) can be dropped in
  and only the TX1/TX2/TX3 pairs will be used.
- The loader also reads `total_line_loss_frac` if present in the source file, but it is
  **not** currently propagated to GenX by this version of PG; keep the column if your
  source has it.
- `total_interconnect_annuity_mw` and `total_interconnect_cost_mw` are adjusted from
  `dollar_year` to `target_usd_year` (2024) using `dollar_year_table` (cpi_data.csv).

## Current contents (working stand-in)

The file currently shipped as `network_costs_tx_3_zone.csv` is a **derived placeholder**:

- Derived from `PowerGenome-data/data/network_costs_ReEDS.csv`
- Filtered to the 7 ERCOT BAs, intra-zone BA pairs excluded, remaining BA pairs
  aggregated to model zones TX1/TX2/TX3 (firm-TTC-weighted for costs, MW-weighted
  for loss)
- `dollar_year: 2018`

Example rows (values will be replaced by your real file):

```
start_region,dest_region,total_interconnect_annuity_mw,total_interconnect_cost_mw,total_line_loss_frac,dollar_year
TX1,TX2,20122.182199850056,422792.64852591325,0.02622934463253593,2018
TX1,TX3,19754.116404287553,415059.1178883252,0.0217595512763129,2018
TX2,TX3,14756.300945304563,310048.65660928376,0.026890711194856948,2018
```

Replace the contents (keep the header row) with your own values and re-run
`run_powergenome` — no other changes needed.
