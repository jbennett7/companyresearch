test_that("history_coverage returns one row per map metric, in map order", {
    local_mocked_bindings(
        get_companyfacts = function(cik, useragent, cache, refresh) make_facts(),
        .package = "secfilings")
    h <- history_coverage(company_history("123", useragent = "ua"))
    expect_identical(nrow(h), 17L)
    expect_identical(
        vapply(h, function(x) class(x)[1], character(1)),
        c(metric = "character", n_q = "integer", n_fy = "integer", n_instant = "integer",
          n_derived = "integer", first_end = "Date", last_end = "Date", missing_q = "integer",
          tags = "character"))
})

test_that("history_coverage counts a complete revenue history", {
    expect_identical(history_coverage(derive_quarters(make_resolved())) |>
        dplyr::filter(metric == "revenue") |>
        dplyr::select(n_q, n_fy, n_derived, missing_q, tags),
        tibble::tibble(n_q = 4L, n_fy = 1L, n_derived = 2L, missing_q = 0L, tags = "Revenues"))
})

test_that("history_coverage counts quarters missing between reported ones", {
    expect_identical(history_coverage(derive_quarters(make_resolved())) |>
        dplyr::filter(metric == "interest_expense") |>
        dplyr::select(n_q, n_fy, n_derived, missing_q),
        tibble::tibble(n_q = 2L, n_fy = 1L, n_derived = 1L, missing_q = 2L))
})

test_that("history_coverage balance-sheet instants", {
    expect_identical(history_coverage(derive_quarters(make_resolved())) |>
        dplyr::filter(metric == "total_assets") |>
        dplyr::select(n_instant, n_q, missing_q),
        tibble::tibble(n_instant = 1L, n_q = 0L, missing_q = 0L))
})

test_that("history_coverage reports metrics without data as zeros and NA", {
    expect_identical(history_coverage(derive_quarters(make_resolved())) |>
        dplyr::filter(metric == "capex"),
        tibble::tibble(metric = "capex", n_q = 0L, n_fy = 0L, n_instant = 0L,
                       n_derived = 0L, first_end = as.Date(NA_character_),
                       last_end = as.Date(NA_character_), missing_q = 0L,
                       tags = NA_character_))
})

test_that("history_coverage lists tags in order of first use", {
    d <- derive_quarters(make_resolved()) |>
        dplyr::mutate(
            tag = dplyr::if_else(
                metric == "interest_expense" & end == as.Date("2024-03-31"),
                "InterestExpenseNonoperating", tag))
    expect_identical(
        dplyr::filter(history_coverage(d), metric == "interest_expense")$tags,
        "InterestExpenseNonoperating, InterestExpense")
})

test_that("history_coverage uses the map it is given", {
    h <- derive_quarters(make_resolved())
    rev_map <- dplyr::filter(metric_map(), metric == "revenue")
    expect_identical(history_coverage(h, map = rev_map)$metric, "revenue")
})

test_that("history_coverage shows AT&T's interest tag switch", {
    skip_on_cran()
    skip_if_offline("www.sec.gov");
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_if(ua == "", "SEC_USERAGENT not set")
    suppressMessages({
        cf <- secfilings::get_companyfacts("732717", ua, withr::local_tempdir())
    })
    h <- history_coverage(derive_quarters(resolve_metrics(cf)))
    expect_true("InterestExpense, InterestExpenseNonoperating" %in% h$tags)
    expect_gt(h$n_fy[h$metric == "revenue"], 17)
})
