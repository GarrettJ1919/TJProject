"""
Fills in the Before/After stat columns (Games, Games Started, Innings
Pitched, K-BB%, ERA-, FIP-) for each pitcher in the TJ surgery spreadsheet.

Setup (run once):
    pip install pybaseball pandas openpyxl

Usage:
    python pull_pitcher_stats.py

How it works:
- G, GS, IP, K-BB%, ERA-, and FIP- are Fangraphs stats (not
  Baseball-Reference stats), so this pulls from Fangraphs in bulk: one
  request per season covering every pitcher in MLB that year, rather than
  one request per player. For a 2018-2023 surgery window this needs
  roughly 2015-2026, so ~10-12 requests total.
- Matches each pitcher to their Fangraphs rows using "Fangraphs ID (helper
  - for matching)" when available (exact match), and falls back to name
  matching for anyone missing that ID.
- "Before" and "After" values are aggregated across YEARS_BEFORE /
  YEARS_AFTER seasons: G, GS, and IP are summed (total workload across the
  window); K-BB%, ERA-, and FIP- are innings-weighted averages (so a
  30-inning season counts more than a 5-inning cameo).
- pybaseball caches each season's table locally after the first pull, so
  re-running the script is fast after the first time.
"""

import pandas as pd
from pybaseball import pitching_stats

# ---- CONFIG ----
INPUT_FILE = "TJ_Surgery_2018_2023_Pitchers_Trimmed.xlsx"
INPUT_SHEET = "MLB Pitchers 2018-2023 TJ"
OUTPUT_FILE = "TJ_Surgery_2018_2023_Pitchers_FILLED.xlsx"
YEARS_BEFORE = 3   # how many seasons before surgery to aggregate
YEARS_AFTER = 3    # how many seasons after surgery to aggregate

ID_COL = "Fangraphs ID (helper - for matching)"
NAME_COL = "Player"
SURGERY_DATE_COL = "Surgery Date"

STAT_COLS = {
    # Fangraphs column name -> (Before column, After column, aggregation)
    "G":     ("Games - Before", "Games - After", "sum"),
    "GS":    ("Games Started - Before", "Games Started - After", "sum"),
    "IP":    ("Innings Pitched - Before", "Innings Pitched - After", "sum"),
    "K-BB%": ("K-BB% - Before", "K-BB% - After", "ip_weighted"),
    "ERA-":  ("ERA - Before", "ERA - After", "ip_weighted"),
    "FIP-":  ("FIP - Before", "FIP - After", "ip_weighted"),
}

# ---- LOAD YOUR PITCHER LIST ----
df = pd.read_excel(INPUT_FILE, sheet_name=INPUT_SHEET)
df["Surgery Year"] = pd.to_datetime(df[SURGERY_DATE_COL]).dt.year

# ---- FIGURE OUT WHICH SEASONS WE ACTUALLY NEED ----
min_year = int(df["Surgery Year"].min()) - YEARS_BEFORE
max_year = int(df["Surgery Year"].max()) + YEARS_AFTER
max_year = min(max_year, 2026)  # 2026 season is in progress -- stats will be partial

print(f"Pulling Fangraphs season pitching tables for {min_year}-{max_year}...")

season_tables = {}
for year in range(min_year, max_year + 1):
    try:
        season_tables[year] = pitching_stats(year, year, qual=0)
        print(f"  {year}: {len(season_tables[year])} pitcher-seasons")
    except Exception as e:
        print(f"  {year}: FAILED ({e})")


def get_player_seasons(row, years):
    """Pull a player's rows across a list of seasons, matching by
    Fangraphs ID first and falling back to name matching."""
    frames = []
    pid = row.get(ID_COL)
    name = row.get(NAME_COL)
    for yr in years:
        table = season_tables.get(yr)
        if table is None:
            continue
        match = pd.DataFrame()
        if pd.notna(pid) and "IDfg" in table.columns:
            match = table[table["IDfg"] == pid]
        if match.empty:
            match = table[table["Name"].str.contains(str(name), case=False, na=False, regex=False)]
        if not match.empty:
            frames.append(match)
    if frames:
        return pd.concat(frames, ignore_index=True)
    return pd.DataFrame()


# ---- AGGREGATE STATS FOR EACH PLAYER, BEFORE AND AFTER ----
unmatched = []

for idx, row in df.iterrows():
    surgery_year = row["Surgery Year"]
    pre_years = range(surgery_year - YEARS_BEFORE, surgery_year)
    post_years = range(surgery_year + 1, surgery_year + YEARS_AFTER + 1)

    for label, years in [("Before", pre_years), ("After", post_years)]:
        seasons = get_player_seasons(row, years)
        if seasons.empty:
            unmatched.append({"Player": row[NAME_COL], "Period": label, "Years checked": list(years)})
            continue

        total_ip = seasons["IP"].sum()
        for fg_col, (before_col, after_col, agg) in STAT_COLS.items():
            target_col = before_col if label == "Before" else after_col
            if fg_col not in seasons.columns:
                continue
            if agg == "sum":
                value = seasons[fg_col].sum()
            elif agg == "ip_weighted" and total_ip > 0:
                value = (seasons[fg_col] * seasons["IP"]).sum() / total_ip
            else:
                value = seasons[fg_col].mean()
            df.at[idx, target_col] = round(value, 3)

unmatched_df = pd.DataFrame(unmatched)

# ---- SAVE ----
with pd.ExcelWriter(OUTPUT_FILE, engine="openpyxl") as writer:
    df.to_excel(writer, sheet_name=INPUT_SHEET, index=False)
    unmatched_df.to_excel(writer, sheet_name="Unmatched - Check Manually", index=False)

print(f"\nDone. {len(unmatched_df)} player-periods had no matching season data (check that tab).")
print(f"Saved to {OUTPUT_FILE}")
