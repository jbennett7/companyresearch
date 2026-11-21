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
