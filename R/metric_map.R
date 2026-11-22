#' Default map from metrics to us-gaap tags, in priority order
#'
#' Lists the metrics [company_history()] builds and the companyfacts tags each
#' one can come from. For each period, a metric takes the highest-priority tag
#' with a value, so a company that switches tags keeps a continuous history.
#'
#' Debt is split into current and noncurrent because few filers tag a total.
#' Equity falls back to the tag including noncontrolling interest (always, for
#' AT&T), which understates return on equity.
#'
#' To cover a company the default misses, pass a modified copy to the `map`
#' argument of [company_history()]. Each metric must keep a single
#' `period_type`, `unit` and `additive` value, and a tag may appear under only
#' one metric.
#'
#' @return A tibble with one row per metric and candidate tag:
#'   \describe{
#'     \item{metric}{Metric name, e.g. `"revenue"`.}
#'     \item{taxonomy}{Taxonomy of the tag; currently always `"us-gaap"`.}
#'     \item{tag}{companyfacts tag name.}
#'     \item{priority}{Integer, 1 = preferred; used per period.}
#'     \item{period_type}{`"duration"` (flows, e.g. revenue) or `"instant"`
#'       (balance-sheet values, e.g. total assets).}
#'     \item{unit}{companyfacts unit: `"USD"`, `"USD/shares"` or `"shares"`.}
#'     \item{additive}{`TRUE` for flow metrics whose quarters can be derived by
#'       subtracting year-to-date values; `FALSE` for per-share, average-share
#'       and instant metrics.}
#'   }
#'
#' @examples
#' m <- metric_map()
#' # add a tag for a company that reports revenue under a different name
#' m <- dplyr::add_row(m, metric = "revenue", taxonomy = "us-gaap",
#'                     tag = "RevenuesNetOfInterestExpense", priority = 4L,
#'                     period_type = "duration", unit = "USD", additive = TRUE)
#' @export
metric_map <- function() {
    tibble::tribble(
        ~metric, ~taxonomy, ~tag, ~priority, ~period_type, ~unit, ~additive,
        "revenue", "us-gaap",  "Revenues", 1L, "duration", "USD", TRUE,
        "revenue", "us-gaap",  "RevenueFromContractWithCustomerExcludingAssessedTax", 2L, "duration", "USD", TRUE,
        "revenue", "us-gaap",  "SalesRevenueNet", 3L, "duration", "USD", TRUE,
        "operating_income", "us-gaap",  "OperatingIncomeLoss", 1L, "duration", "USD",  TRUE,
        "net_income", "us-gaap",  "NetIncomeLoss", 1L, "duration", "USD", TRUE,
        "interest_expense", "us-gaap",  "InterestExpenseNonoperating", 1L, "duration", "USD", TRUE,
        "interest_expense", "us-gaap",  "InterestExpense", 2L, "duration", "USD", TRUE,
        "income_tax", "us-gaap",  "IncomeTaxExpenseBenefit", 1L, "duration", "USD", TRUE,
        "depreciation_amortization", "us-gaap",  "DepreciationDepletionAndAmortization", 1L, "duration", "USD", TRUE,
        "depreciation_amortization", "us-gaap",  "DepreciationAndAmortization", 2L, "duration", "USD", TRUE,
        "eps_diluted", "us-gaap",  "EarningsPerShareDiluted", 1L, "duration", "USD/shares", FALSE,
        "diluted_shares", "us-gaap",  "WeightedAverageNumberOfDilutedSharesOutstanding", 1L, "duration", "shares", FALSE,
        "operating_cash_flow", "us-gaap",  "NetCashProvidedByUsedInOperatingActivities", 1L, "duration", "USD", TRUE,
        "capex", "us-gaap",  "PaymentsToAcquirePropertyPlantAndEquipment", 1L, "duration", "USD", TRUE,
        "dividends_paid", "us-gaap",  "PaymentsOfDividendsCommonStock", 1L, "duration", "USD", TRUE,
        "dividends_paid", "us-gaap",  "PaymentsOfDividends", 2L, "duration", "USD", TRUE,
        "cash", "us-gaap",  "CashAndCashEquivalentsAtCarryingValue", 1L, "instant", "USD", FALSE,
        "cash", "us-gaap",  "CashCashEquivalentsRestrictedCashAndRestrictedCashEquivalents", 2L, "instant", "USD", FALSE,
        "total_assets", "us-gaap",  "Assets", 1L, "instant", "USD", FALSE,
        "equity", "us-gaap",  "StockholdersEquity", 1L, "instant", "USD", FALSE,
        "equity", "us-gaap",  "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest", 2L, "instant", "USD", FALSE,
        "debt_current", "us-gaap",  "DebtCurrent", 1L, "instant", "USD", FALSE,
        "debt_current", "us-gaap",  "LongTermDebtCurrent", 2L, "instant", "USD", FALSE,
        "debt_noncurrent", "us-gaap",  "LongTermDebtAndCapitalLeaseObligations", 1L, "instant", "USD", FALSE,
        "debt_noncurrent", "us-gaap",  "LongTermDebtNoncurrent", 2L, "instant", "USD", FALSE
    )
}
