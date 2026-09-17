"""
Pulls ERA, WHIP, and IP for each MLB-level pitcher in the TJ surgery list,
for a configurable number of seasons before and after their surgery.

Setup (run once):
    pip install pybaseball pandas openpyxl

Usage:
    python pull_pitcher_stats.py

Notes:
- Pulls season-level tables from Baseball-Reference in BULK (one call per
  year), not one call per player, so 642 pitchers only needs ~20-40 requests
  total instead of 642+.
- pybaseball caches each season's table locally after the first pull, so
  re-running the script is fast and doesn't re-hit the website.
- Matching is done by player name. Names with accents, suffixes (Jr./Sr.),
  or nicknames may not match automatically -- check the "unmatched" sheet
  in the output and fix those by hand.
"""

import pandas as pd
from pybaseball import pitching_stats_bref
from pathlib import Path

# ---- CONFIG ----
INPUT_FILE = "TJ_Surgery_2018_2023_Pitchers.xlsx"
INPUT_SHEET = "MLB Pitchers 2018-2023 TJ"
OUTPUT_FILE = "TJ_Pitchers_2018_2023_ERA_WHIP_IP.xlsx"
YEARS_BEFORE = 3   # how many seasons before surgery to pull
YEARS_AFTER = 3    # how many seasons after surgery to pull

# ---- LOAD YOUR PITCHER LIST ----
df = pd.read_excel(INPUT_FILE, sheet_name=INPUT_SHEET)
df["Surgery Year"] = pd.to_datetime(df["TJ Surgery Date"]).dt.year

# ---- FIGURE OUT WHICH SEASONS WE ACTUALLY NEED ----
min_year = int(df["Surgery Year"].min()) - YEARS_BEFORE
max_year = int(df["Surgery Year"].max()) + YEARS_AFTER
# Baseball-Reference bulk tables are readily available from 1901 onward,
# and pybaseball handles modern seasons best -- clip to a sane floor.
min_year = max(min_year, 1974)
max_year = min(max_year, 2026)  # 2026 season is in progress as of writing -- stats will be partial for that year

print(f"Pulling season pitching tables for {min_year}-{max_year}...")

season_tables = {}
for year in range(min_year, max_year + 1):
    try:
        season_tables[year] = pitching_stats_bref(year)
        print(f"  {year}: {len(season_tables[year])} pitcher-seasons")
    except Exception as e:
        print(f"  {year}: FAILED ({e})")

# ---- MATCH EACH PITCHER TO THEIR PRE/POST SEASON ROWS ----
results = []
unmatched = []

for _, row in df.iterrows():
    name = row["Player"]
    surgery_year = row["Surgery Year"]

    pre_years = range(surgery_year - YEARS_BEFORE, surgery_year)
    post_years = range(surgery_year + 1, surgery_year + YEARS_AFTER + 1)

    for label, years in [("Pre", pre_years), ("Post", post_years)]:
        for yr in years:
            table = season_tables.get(yr)
            if table is None:
                continue
            match = table[table["Name"].str.contains(name, case=False, na=False, regex=False)]
            if match.empty:
                unmatched.append({"Player": name, "Year": yr, "Period": label})
                continue
            for _, m in match.iterrows():
                results.append({
                    "Player": name,
                    "Surgery Year": surgery_year,
                    "Period": label,
                    "Season": yr,
                    "Team": m.get("Team"),
                    "ERA": m.get("ERA"),
                    "WHIP": m.get("WHIP"),
                    "IP": m.get("IP"),
                    "G": m.get("G"),
                    "GS": m.get("GS"),
                })

results_df = pd.DataFrame(results)
unmatched_df = pd.DataFrame(unmatched)

# ---- SAVE ----
with pd.ExcelWriter(OUTPUT_FILE, engine="openpyxl") as writer:
    results_df.to_excel(writer, sheet_name="ERA WHIP IP by Season", index=False)
    unmatched_df.to_excel(writer, sheet_name="Unmatched - Check Manually", index=False)

print(f"\nDone. Matched {len(results_df)} pitcher-seasons.")
print(f"Unmatched (need manual check): {len(unmatched_df)}")
print(f"Saved to {OUTPUT_FILE}")
