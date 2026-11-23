test_that("add_derived_metrics keeps the input rows unchanged", {
    h <- make_history()
    out <- add_derived_metrics(h)
    expect_identical(nrow(out), 23L)
    expect_identical(out[seq_len(nrow(h)), ], h)
})

test_that("add_derived_metrics computes fcf as operating cash flow minus capex", {
    h <- add_derived_metrics(make_history())
    expect_equal(h$val[h$metric == "fcf" & h$end == as.Date("2025-03-31")], 200)
    expect_equal(h$val[h$metric == "fcf" & h$period == "Q" &
                 h$end == as.Date("2025-12-31")], 230)
    expect_equal(h$val[h$metric == "fcf" & h$period == "FY"], 750)
})

test_that("add_derived_metrics computes ebitda as operating income plus D&A", {
    h <- add_derived_metrics(make_history())
    expect_equal(h$val[h$metric == "ebitda" & h$end == as.Date("2025-03-31")], 250)
    expect_equal(h$val[h$metric == "ebitda" & h$period == "FY"], 1010)
})

test_that("add_derived_metrics computes total and net debt at balance-sheet dates", {
    h <- add_derived_metrics(make_history())
    expect_equal(h$val[h$metric == "total_debt" & h$end == as.Date("2025-12-31")], 1000)
    expect_equal(h$val[h$metric == "net_debt" & h$end == as.Date("2025-12-31")], 850)
    expect_identical(
        dplyr::filter(h, metric %in% c("total_debt", "net_debt")) |>
            dplyr::select(start, source, tag),
        tibble::tibble(start = as.Date(c(NA, NA)), source = c("computed", "computed"),
                       tag = c(NA_character_, NA_character_)))
})

test_that("add_derived_metrics skips periods with a missing input", {
    h <- add_derived_metrics(make_history())
    expect_identical(nrow(dplyr::filter(h, metric == "fcf",
                                        end == as.Date("2025-06-30"))), 0L)
    expect_identical(nrow(dplyr::filter(h, metric == "total_debt",
                                        end == as.Date("2025-09-30"))), 0L)
    expect_identical(nrow(dplyr::filter(h, metric == "ebitda",
                                        end == as.Date("2025-06-30"))), 0L)
})

test_that("add_derived_metrics dates a computed value by its later input", {
    h <- add_derived_metrics(make_history())
    expect_identical(dplyr::filter(h, metric == "ebitda",
                                   end == as.Date("2025-03-31")) |>
                     dplyr::select(filed, first_filed),
                     tibble::tibble(filed = as.Date("2025-05-10"),
                                    first_filed = as.Date("2025-05-10")))
})
