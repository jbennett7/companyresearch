#' Default map from metrics to us-gaap tags, in priority order
#'
#' For each period, a metric takes the highest-priority tag with a value. Debt
#' is split into current and noncurrent because few filers tag a quarterly
#' total. Equity falls back to the tag including noncontrolling interest
#' (always, for AT&T), which understates return on equity.
#'
#' @noRd
metric_map <- function() {
    tibble::tribble(
        ~metric, ~taxonomy, ~tag, ~priority, ~period_type, ~unit,
        "revenue", "us-gaap",  "Revenues", 1L, "duration", "USD",
        "revenue", "us-gaap",  "RevenueFromContractWithCustomerExcludingAssessedTax", 2L, "duration", "USD",
        "revenue", "us-gaap",  "SalesRevenueNet", 3L, "duration", "USD",
        "operating_income", "us-gaap",  "OperatingIncomeLoss", 1L, "duration", "USD",
        "net_income", "us-gaap",  "NetIncomeLoss", 1L, "duration", "USD",
        "interest_expense", "us-gaap",  "InterestExpenseNonoperating", 1L, "duration", "USD",
        "interest_expense", "us-gaap",  "InterestExpense", 2L, "duration", "USD",
        "income_tax", "us-gaap",  "IncomeTaxExpenseBenefit", 1L, "duration", "USD",
        "depreciation_amortization", "us-gaap",  "DepreciationDepletionAndAmortization", 1L, "duration", "USD",
        "depreciation_amortization", "us-gaap",  "DepreciationAndAmortization", 2L, "duration", "USD",
        "eps_diluted", "us-gaap",  "EarningsPerShareDiluted", 1L, "duration", "USD/shares",
        "diluted_shares", "us-gaap",  "WeightedAverageNumberOfDilutedSharesOutstanding", 1L, "duration", "shares",
        "operating_cash_flow", "us-gaap",  "NetCashProvidedByUsedInOperatingActivities", 1L, "duration", "USD",
        "capex", "us-gaap",  "PaymentsToAcquirePropertyPlantAndEquipment", 1L, "duration", "USD",
        "dividends_paid", "us-gaap",  "PaymentsOfDividendsCommonStock", 1L, "duration", "USD",
        "dividends_paid", "us-gaap",  "PaymentsOfDividends", 2L, "duration", "USD",
        "cash", "us-gaap",  "CashAndCashEquivalentsAtCarryingValue", 1L, "instant", "USD",
        "cash", "us-gaap",  "CashCashEquivalentsRestrictedCashAndRestrictedCashEquivalents", 2L, "instant", "USD",
        "total_assets", "us-gaap",  "Assets", 1L, "instant", "USD",
        "equity", "us-gaap",  "StockholdersEquity", 1L, "instant", "USD",
        "equity", "us-gaap",  "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest", 2L, "instant", "USD",
        "debt_current", "us-gaap",  "DebtCurrent", 1L, "instant", "USD",
        "debt_current", "us-gaap",  "LongTermDebtCurrent", 2L, "instant", "USD",
        "debt_noncurrent", "us-gaap",  "LongTermDebtAndCapitalLeaseObligations", 1L, "instant", "USD",
        "debt_noncurrent", "us-gaap",  "LongTermDebtNoncurrent", 2L, "instant", "USD"
    )
}
