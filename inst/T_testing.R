cf <- secfilings::get_companyfacts("732717",Sys.getenv("SEC_USERAGENT"),
                                   cache = withr::local_tempdir())
#cf |> dplyr::filter(tag %in% c("Revenues", "RevenueFromContractWithCustomerExcludingAssessedTax",
#                               "InterestExpense", "InterestExpenseNonoperating",
#                               "LongTermDebt", "LongTermDebtNoncurrent")) |>
#    dplyr::group_by(tag) |>
#    dplyr::summarize(first = min(end), last = max(end), n = dplyr::n())

#cf |> dplyr::filter(
#    tag %in% c("DebtCurrent",
#               "LongTermDebtCurrent",
#               "LongTermDebtAndCapitalLeaseObligations",
#               "StockholdersEquity",
#               "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest")) |>
#    dplyr::group_by(tag) |>
#    dplyr::summarize(first = min(end), last = max(end), n = dplyr::n())

cf |>
    dplyr::filter(tag %in% c("InterestExpense", "InterestExpenseNonoperating"),
                  end >= as.Date("2022-12-31"), end <= as.Date("2024-06-30")) |>
    dplyr::distinct(tag, start, end, val) |>
    tidyr::pivot_wider(names_from = tag, values_from = val) |>
    dplyr::arrange(end, start)
