# companyresearch: scope

## Purpose

A research tool for studying one public company in depth. Given a ticker, it
builds a long history of the company's fundamentals from SEC data, turns that
history into financial health and valuation measures, and presents the result
as a one-page tearsheet.

## Unit of analysis

One company at a time. Screening, sector-wide comparisons and peer groups are
out of scope for now.

## Capabilities, in build order

0. **Prerequisite in secfilings: `get_companyfacts(cik, useragent, cache)`.**
   It downloads `data.sec.gov/api/xbrl/companyfacts/CIK##########.json`
   (padded CIK), caches it, and returns a long tibble: taxonomy, tag, unit,
   start, end, value, accession, form, fy, fp, filed, frame.
1. **Fundamentals history.**
   - **The metric map:** a package table of each metric, its statement type
     (duration or instant), its unit, and its candidate tags in priority
     order. It starts with about 15 metrics: revenue, operating income, net
     income, operating cash flow, capex, cash, total debt, equity, interest
     expense, diluted shares, dividends paid, and so on.
   - **The output:** the history for each metric is resolved through the map,
     giving one value per metric per period.
   - **Quarters:** single quarters are worked out from year-to-date figures
     (Q2 = 6M − Q1, Q4 = FY − 9M). Amended values are handled by taking the
     most recently filed one.
   - **Tags:** when a company switches tags, the history continues on the next
     tag in the map's priority order, and the output records which tag each
     value came from.
   - **Output shape:** a tidy tibble with ticker, metric, period end, period
     type (Q/FY), value and source tag.
2. **Financial health ratios.** These are computed from the history as time
   series:
   - gross, operating and net margins
   - free cash flow and free cash flow margin
   - debt / equity, net debt / EBITDA and interest coverage
   - return on equity and return on invested capital
   - the dividend payout ratio and dividend coverage by free cash flow
   - trailing-twelve-month versions where they make sense
3. **Valuation.**
   - **Prices:** daily prices and dividends from tidyquant/quantmod.
   - **Joining:** each fundamentals value is matched to the price on or after
     its filing date, so a value is never used before the market could have
     known it.
   - **Measures:** P/E, P/S, EV/EBITDA, free cash flow yield and dividend
     yield, each shown against the company's own history (percentile, median,
     range).
4. **Tearsheet.**
   - **The report:** a Quarto HTML template in `inst/`, taking a ticker as its
     parameter. It holds a company header, key metric trends, ratio charts and
     a valuation-vs-history panel.
   - **Latest statements:** the latest income, balance sheet and cash flow
     statements as presented, through xbrlstatements.

## Data sources

| Data                           | Source                       | Package                   |
|--------------------------------|------------------------------|---------------------------|
| Fundamentals history           | SEC companyfacts API         | secfilings (new function) |
| Latest as-presented statements | Latest 10-K/10-Q XBRL        | secfilings → xbrlstatements |
| Company identity, filing list  | SEC submissions              | secfilings                |
| Prices, dividends              | Yahoo via tidyquant/quantmod | companyresearch           |

## Out of scope (for now)

- Segment and geographic breakdowns
- Insider and large-holder activity (Form 4, 13G)
- Filing-event detection: restatements, new tags, unusual items
- Peer comparison and screening
- Market-wide analysis: commodities, sector correlations, technical indicators
  (a future Markets package)
- Portfolio tracking and IRR

## Known risks

- **Tag switches and company-specific extension tags.** The metric map covers
  `us-gaap` tags only. Company-specific tags (AT&T's `t:` goodwill impairment,
  for example) won't be picked up, and the map should make that limit
  explicit.
- **Quarter derivation.** Filers mix year-to-date and single-quarter values,
  and the 10-K's full-year value can be confused with Q4. Identify periods by
  their start and end dates, not by SEC's fiscal year/period labels.
- **Companies outside the US-GAAP mould.** Banks and REITs have different
  revenue and debt concepts, so the first version targets ordinary operating
  companies.
- **Yahoo data.** It's an unofficial source and can change or break.

## Conventions

- **Layering:** fetching goes in secfilings, and statement rendering in
  xbrlstatements. companyresearch only analyses.
- **User agent:** comes from `Sys.getenv("SEC_USERAGENT")` and is never
  hardcoded.
- **Cache:** set with a `cache` argument, default `./.cache`, and ignored by
  git and the package build.
- **Package conventions:** call imports as `pkg::fn`; mark internal functions
  `@noRd`.
- **Tests:** testthat 3e, with mocked HTTP and small hand-built fixtures, plus
  one real-company regression snapshot (AT&T).

## First deliverables

1. Package setup:
   - `git init`, then commit the old files once before deleting them
   - a real DESCRIPTION, license and ignore files
   - testthat
   - removing the hardcoded user agents
2. `secfilings::get_companyfacts()`, with mocked tests.
3. The metric map, plus the history function for one metric type (duration),
   with derived quarters.
