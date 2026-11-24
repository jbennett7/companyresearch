make_facts <- function() {
    tibble::tribble(
        ~taxonomy, ~tag, ~unit, ~start, ~end, ~val, ~accn, ~form, ~filed,
        "us-gaap", "InterestExpense", "USD", "2025-01-01", "2025-03-31", 100, "A", "10-Q", "2025-05-01",
        "us-gaap", "InterestExpenseNonoperating", "USD", "2025-01-01", "2025-03-31", 100, "A", "10-Q", "2025-05-01",
        "us-gaap", "InterestExpense", "USD", "2024-01-01", "2024-03-31", 90, "B", "10-Q", "2024-05-01",
        "us-gaap", "Revenues", "USD", "2024-01-01", "2024-12-31", 1000, "C", "10-K", "2025-02-15",
        "us-gaap", "Revenues", "USD", "2024-01-01", "2024-12-31", 1010, "D", "10-K", "2026-02-15",
        "us-gaap", "Revenues", "USD", "2025-01-01", "2025-12-31", 1200, "D", "10-K", "2026-02-15",
        "us-gaap", "RevenueFromContractWithCustomerExcludingAssessedTax", "USD", "2025-01-01", "2025-12-31", 1150, "E", "10-K/A", "2026-04-01",
        "us-gaap", "Assets", "USD", NA_character_, "2024-12-31", 5000, "C", "10-K", "2025-02-15",
        "us-gaap", "Assets", "USD", NA_character_, "2024-12-31", 5000, "D", "10-K", "2026-02-15",
        "ifrs-full", "Assets", "USD", NA_character_, "2023-12-31", 4000, "F", "20-F", "2024-03-01",
        "us-gaap", "Revenues", "EUR", "2023-01-01", "2023-12-31", 800, "G", "10-K", "2024-02-15",
        "us-gaap", "GrossProfit", "USD", "2025-01-01", "2025-12-31", 400, "D", "10-K", "2026-02-15"
    ) |>
    dplyr::mutate(
        start = as.Date(start), end = as.Date(end), filed = as.Date(filed),
        fy = NA_integer_, fp = NA_character_, frame = NA_character_
    ) |>
    dplyr::select(taxonomy, tag, unit, start, end, val, accn, fy, fp, form, filed, frame)
}

make_resolved <- function() {
    tibble::tribble(
        ~metric, ~tag, ~start, ~end, ~val, ~accn, ~form, ~filed,
        "revenue", "Revenues", "2025-01-01", "2025-03-31", 100, "A", "10-Q", "2025-05-01",
        "revenue", "Revenues", "2025-01-01", "2025-06-30", 212, "B", "10-Q", "2025-08-01",
        "revenue", "Revenues", "2025-04-01", "2025-06-30", 110, "B", "10-Q", "2025-08-01",
        "revenue", "Revenues", "2025-01-01", "2025-09-30", 330, "C", "10-Q", "2025-11-01",
        "revenue", "Revenues", "2025-01-01", "2025-12-31", 460, "D", "10-K", "2026-02-15",
        "revenue", "Revenues", "2023-09-01", "2023-12-31", 40,  "E", "10-K", "2024-02-15",
        "interest_expense", "InterestExpense", "2024-01-01", "2024-03-31", 50, "F", "10-Q", "2024-05-01",
        "interest_expense", "InterestExpense", "2024-01-01", "2024-09-30", 160, "G", "10-Q", "2024-11-01",
        "interest_expense", "InterestExpense", "2024-01-01", "2024-12-31", 220, "H", "10-K", "2025-02-15",
        "eps_diluted", "EarningsPerShareDiluted", "2025-01-01", "2025-03-31", 0.5, "A", "10-Q", "2025-05-01",
        "eps_diluted", "EarningsPerShareDiluted", "2025-01-01", "2025-06-30", 1.1, "B", "10-Q", "2025-08-01",
        "eps_diluted", "EarningsPerShareDiluted", "2025-01-01", "2025-12-31", 2.3, "D", "10-K", "2026-02-15",
        "total_assets", "Assets", NA_character_, "2025-12-31", 5000, "D", "10-K", "2026-02-15"
    ) |>
    dplyr::mutate(
        start = as.Date(start), end = as.Date(end), filed = as.Date(filed),
        first_filed = filed)
}

make_history <- function() {
    tibble::tribble(
        ~metric,                    ~period,    ~start,       ~end,         ~val,  ~filed,       ~tag,                           ~source,    ~first_filed,
        "operating_cash_flow",       "Q",       "2025-01-01", "2025-03-31", 300,   "2025-05-01", "NetCashProvidedByUsedInOperatingActivities",            "reported", "2025-05-01",
        "capex",                     "Q",       "2025-01-01", "2025-03-31", 100,   "2025-05-01", "PaymentsToAcquirePropertyPlantAndEquipment", "reported", "2025-05-01",
        "operating_income",          "Q",       "2025-01-01", "2025-03-31", 200,   "2025-05-01", "OperatingIncomeLoss",              "reported", "2025-05-01",
        "operating_income",          "Q",       "2025-04-01", "2025-06-30", 210,   "2025-08-01", "OperatingIncomeLoss",              "reported", "2025-08-01",
        "depreciation_amortization", "Q",       "2025-01-01", "2025-03-31", 50,    "2025-05-10", "DepreciationDepletionAndAmortization",  "reported", "2025-05-10",
        "operating_cash_flow",       "Q",       "2025-10-01", "2025-12-31", 350,   "2026-02-15", "NetCashProvidedByUsedInOperatingActivities",            "reported", "2026-02-15",
        "capex",                     "Q",       "2025-10-01", "2025-12-31", 120,   "2026-02-15", "PaymentsToAcquirePropertyPlantAndEquipment", "reported", "2026-02-15",
        "operating_cash_flow",       "FY",      "2025-01-01", "2025-12-31", 1200,  "2026-02-15", "NetCashProvidedByUsedInOperatingActivities",            "reported", "2026-02-15",
        "capex",                     "FY",      "2025-01-01", "2025-12-31", 450,   "2026-02-15", "PaymentsToAcquirePropertyPlantAndEquipment", "reported", "2026-02-15",
        "operating_income",          "FY",      "2025-01-01", "2025-12-31", 800,   "2026-02-15", "OperatingIncomeLoss",              "reported", "2026-02-15",
        "depreciation_amortization", "FY",      "2025-01-01", "2025-12-31", 210,   "2026-02-15", "DepreciationDepletionAndAmortization",  "reported", "2026-02-15",
        "capex",                     "Q",       "2025-04-01", "2025-06-30", 110,   "2025-08-01", "PaymentsToAcquirePropertyPlantAndEquipment",    "reported", "2025-08-01",
        "debt_noncurrent",           "instant", NA_character_, "2025-09-30", 880,  "2025-11-01", "LongTermDebtAndCapitalLeaseObligations",   "reported", "2025-11-01",
        "debt_current",              "instant", NA_character_, "2025-12-31", 100,  "2026-02-15", "DebtCurrent",           "reported", "2026-02-15",
        "debt_noncurrent",           "instant", NA_character_, "2025-12-31", 900,  "2026-02-15", "LongTermDebtAndCapitalLeaseObligations",   "reported", "2026-02-15",
        "cash",                      "instant", NA_character_, "2025-12-31", 150,  "2026-02-15", "CashAndCashEquivalentsAtCarryingValue", "reported", "2026-02-15"
    ) |>
    dplyr::mutate(start = as.Date(start), end = as.Date(end),
                  filed = as.Date(filed), first_filed = as.Date(first_filed)) |>
    dplyr::select(metric, period, start, end, val, source, tag, filed, first_filed)
}

make_quarters <- function() {
    tibble::tribble(
        ~metric, ~period, ~start, ~end, ~val, ~filed, ~tag, ~source, ~first_filed,
        "revenue", "Q", "2024-10-01", "2024-12-31", 90, "2025-02-15", "Revenues", "reported", "2025-02-15",
        "revenue", "Q", "2025-01-01", "2025-03-31", 100, "2026-02-15", "Revenues", "reported", "2025-05-01",
        "revenue", "Q", "2025-04-01", "2025-06-30", 110, "2025-08-01", "Revenues", "reported", "2025-08-01",
        "revenue", "Q", "2025-07-01", "2025-09-30", 120, "2025-11-01", "Revenues", "reported", "2025-11-01",
        "revenue", "Q", "2025-10-01", "2025-12-31", 130, "2026-02-15", "Revenues", "reported", "2026-02-15",
        "revenue", "FY", "2025-01-01", "2025-12-31", 460, "2026-02-15", "Revenues", "reported", "2026-02-15",
        "interest_expense", "Q", "2024-01-01", "2024-03-31", 10, "2024-05-01", "InterestExpense", "reported", "2024-05-01",
        "interest_expense", "Q", "2024-04-01", "2024-06-30", 11, "2024-08-01", "InterestExpense", "reported", "2024-08-01",
        "interest_expense", "Q", "2024-10-01", "2024-12-31", 13, "2025-02-15", "InterestExpense", "reported", "2025-02-15",
        "interest_expense", "Q", "2025-01-01", "2025-03-31", 14, "2025-05-01", "InterestExpense", "reported", "2025-05-01",
        "eps_diluted", "Q", "2025-01-01", "2025-03-31", 0.5, "2025-05-01", "EarningsPerShareDiluted", "reported", "2025-05-01",
        "eps_diluted", "Q", "2025-04-01", "2025-06-30", 0.6, "2025-08-01", "EarningsPerShareDiluted", "reported", "2025-11-01",
        "eps_diluted", "Q", "2025-07-01", "2025-09-30", 0.6, "2025-11-01", "EarningsPerShareDiluted", "reported", "2025-11-01",
        "eps_diluted", "Q", "2025-10-01", "2025-12-31", 0.6, "2026-02-15", "EarningsPerShareDiluted", "reported", "2026-02-15",
        "total_assets", "instant", NA_character_, "2025-12-31", 5000, "2026-02-15", "Assets", "reported", "2026-02-15"
    ) |>
    dplyr::mutate(start = as.Date(start), end = as.Date(end),
                  filed = as.Date(filed), first_filed = as.Date(first_filed)) |>
    dplyr::select(metric, period, start, end, val, source, tag, filed, first_filed)
}
