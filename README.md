# sportmetrics

Three reusable functions for testing whether an "advanced" sports metric
actually adds value over a traditional stat, or fails in one of three ways:

| Function | Hypothesis | Question it answers |
|---|---|---|
| `test_redundancy()` | H1 — Redundant | Does the advanced metric predict an outcome better than traditional stats alone? |
| `test_reliability()` | H2 — Too noisy | Is the metric stable enough, split-half, to trust for ranking? |
| `test_discriminability()` | H3 — No real spread | Does the metric actually vary enough across players to rank them at all? |

These functions are sport-agnostic. The same three functions get called on
baseball, football, and basketball data — only the data changes.

## Install

Clone the repo, then from R:

```r
# install.packages("devtools") # if you don't already have it
devtools::load_all(".")
```

Or, once this is pushed to GitHub:

```r
devtools::install_github("<your-github-username>/sportmetrics")
```

## Quick start

```r
library(sportmetrics)

# H1: is wRC+ redundant with AVG/HR/RBI for predicting next-season WAR?
test_redundancy(
  data = player_season_data,
  outcome = "next_season_war",
  traditional_vars = c("avg", "hr", "rbi"),
  advanced_var = "wrc_plus"
)

# H2: is wRC+ reliable split-half across plate appearances?
test_reliability(
  data = plate_appearance_data,   # long format: one row per PA per player
  id_col = "player_id",
  value_col = "wOBA_value",
  n_splits = 1000
)

# H3: does wRC+ actually spread players out?
test_discriminability(
  data = player_season_data,
  metric = "wrc_plus"
)
```

## Setting this up as your team's shared repo

```bash
cd sportmetrics
git init
git add .
git commit -m "Initial commit: redundancy, reliability, discriminability functions"
git remote add origin https://github.com/<your-username>/sportmetrics.git
git branch -M main
git push -u origin main
```

Each sport pair should `git pull` before starting, and can extend these
functions (e.g. a weighted variant of `test_reliability()` for football's
small samples) on a branch, then open a PR back to `main` — so every
sport keeps running the same reviewed implementation instead of drifting
into four different ideas of what "compare" means.

## Data shape notes

- `test_redundancy()` and `test_discriminability()` expect one row per
  player (or player-season) — wide format.
- `test_reliability()` expects one row per player per observation unit
  (one row per plate appearance, per game, per possession) — long format.
  This is the one that needs the most data-wrangling before it's usable;
  budget real time for it, especially for football's small in-season
  samples, where you may need to pool multiple seasons to get enough
  observations per player.

## Where this comes from

`test_reliability()` implements a stabilization-style split-half method in
the spirit of Russell Carleton's sabermetric stabilization research and
the FanGraphs Cronbach's-alpha successor to it. Read those before
extending this function — the implementation here is intentionally
simplified for teaching clarity, not a full replication of either.

## A note on how this was built

These functions were drafted by Claude and have not yet been run against
a live R installation or real data — the logic has been reasoned through
carefully, but there is no substitute for actually running the test suite
(`devtools::test()`) and trying each function against a small real dataset
before relying on the results. Treat this as a strong first draft to
verify, not a black box.
