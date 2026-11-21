suppressMessages({
    devtools::load_all('.')
    devtools::load_all('../xbrlstatements')
    library(secfilings)
#    library(tibble)
    library(dplyr)
#    library(XBRL)
#    library(purrr)
#    library(tidyr)
    library(lubridate)
})

useragent <- Sec.getenv("SEC_USERAGENT")
ticker    <- "T"
cik       <- get_cik(ticker, useragent)

filings <- get_submissions(cik, useragent) |>
    filter(
        grepl("^10-[KQ](?:\\/A)?$", form),
        reportDate > as.Date("2022-12-31"),
        isXBRL == 1) |>
    arrange(desc(reportDate))

report <- 1
xbrl   <- process_filing(cik, filings$accessionNumber[report], useragent)
names(xbrl)
#xbrl$elements |>
#    readr::write_csv("../xbrlstatements/tests/testthat/elements.csv")
#form <- filings$form[report]
#is <- build_statement(xbrl, "income", form)
#format_statement(is$data, is$tree) |> print(n = Inf)

#period <- if_else(startsWith(filings$form[report], "10-K"), "FY", "3M")
#period <- period_for("income", filings$form[report])
#role_id <- find_role(xbrl, "income")

#find_role(xbrl, "balance")
#find_role(xbrl, "cash_flow")
#period_for("cash_flow", "10-Q")
#try(find_role(xbrl, "equity"))
#xbrl2 <- xbrl; xbrl2$role$description <- "nothing"
#try(find_role(xbrl2, "income"))

#role_id <- xbrl$role |>
#    filter(
#        type == 'Statement',
#        grepl('statements? of income(?: \\(Unaudited\\))?$',
#              ignore.case=TRUE, description)) |>
#    pull(roleId)
#stopifnot(length(role_id) == 1)

#is_tree     <- role_tree(xbrl, role_id)
#statement   <- flatten_tree(is_tree)
#elt_ids     <- unique(statement$elementId)
#values      <- consolidated_values(xbrl, elt_ids, period)
#date_cols   <- latest_dates(values)
#wide        <- widen(values, date_cols)
#member_rows <- get_member_rows(xbrl, is_tree, statement, period, date_cols)
#is_data     <- merge_members(statement, wide, member_rows)
#format_statement(is_data, is_tree) |> print(n = Inf)

## TESTS
#axis_ids <- xbrl$element$elementId[xbrl$element$substitutionGroup == "xbrldt:dimensionItem"]
#role_no_axes <- xbrl$presentation |>
#    group_by(roleId) |>
#    summarize(has_axes = any(toElementId %in% axis_ids)) |>
#    filter(!has_axes) |>
#    inner_join(xbrl$role, by = "roleId") |>
#    filter(type == "Statement") |>
#    select(roleId, description) |>
#    slice(1) |> pull(roleId)
#no_axes_tree <- role_tree(xbrl, role_no_axes)
#get_member_rows(xbrl, no_axes_tree, flatten_tree(no_axes_tree), period, date_cols)

#label_for(is_tree, "us-gaap_ServiceMember", "bogus-role")
#label_for(is_tree, "us-gaap_StatementLineItems")
#label_for(is_tree, "us-gaap_NoSuchElement")

#cat("span_of checks:\n\t")
#span_of(c("2026-07-01", "2026-01-01", "2025-10-01", NA),
#        c("2026-09-30", "2026-09-30", "2026-09-30", "2026-09-30"))
#
#print_tree(is_tree, fact_status(xbrl))
#names(xbrl$dimension)
#xbrl$dimension |> filter(grepl("ProductOrService", dimension)) |> distinct(dimension, value)

