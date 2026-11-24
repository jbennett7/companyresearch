test_that("add_ttm returns the same shape as input plus some", {
    q <- make_quarters()
    a <- add_ttm(q)
    expect_identical(nrow(a), 17L)
    expect_identical(a[seq_len(nrow(q)), ], q)
})

test_that("add_ttm sums four consecutive quarters", {
    a <- add_ttm(make_quarters())
    expect_identical(dplyr::filter(a, metric == "revenue", source == "computed") |>
        dplyr::select(val, start, period, tag),
        tibble::tibble(val = c(420, 460), start = as.Date(c("2024-10-01", "2025-01-01")),
                      period = c("TTM", "TTM"), tag = c(NA_character_, NA_character_)))
})

test_that("add_ttm at fiscal year end equals the FY value", {
    a <- add_ttm(make_quarters())
    end <- as.Date("2025-12-31")
    expect_equal(a$val[a$metric == "revenue" & a$period == "TTM" & a$end == end],
                 a$val[a$metric == "revenue" & a$period == "FY"  & a$end == end])
})

test_that("add_ttm a gap gives no TTM", {
    a <- add_ttm(make_quarters())
    expect_identical(nrow(dplyr::filter(a, metric == "interest_expense", period == "TTM")),
                     0L)
})

test_that("add_ttm non-additive metrics give no TTM", {
    a <- add_ttm(make_quarters())
    expect_identical(nrow(dplyr::filter(a, metric == "eps_diluted", period == "TTM")),
                     0L)
})

test_that("add_ttm filing dates come from all four quarters", {
    a <- add_ttm(make_quarters())
    expect_identical(dplyr::filter(a, period == "TTM", end == as.Date("2025-09-30")) |>
        dplyr::select(filed, first_filed),
        tibble::tibble(filed = as.Date("2026-02-15"), first_filed = as.Date("2025-11-01")))
})

test_that("add_ttm the map decides additivity", {
    m <- metric_map() |>
        dplyr::mutate(additive = dplyr::if_else(metric == "eps_diluted", TRUE, additive))
    a <- add_ttm(make_quarters(), m)
    expect_equal(dplyr::filter(a, metric == "eps_diluted", period == "TTM")$val, 2.3)
})

test_that("add_ttm on AT&T: TTM revenue at fiscal year end equals FY", {
    skip_on_cran()
    skip_if_offline("www.sec.gov")
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_if(ua == "", "SEC_USERAGENT not set")
    suppressMessages({
        cf <- secfilings::get_companyfacts("732717", ua, withr::local_tempdir())
    })
    a <- add_ttm(derive_quarters(resolve_metrics(cf)))
    end <- as.Date("2023-12-31")
    expect_equal(a$val[a$metric == "revenue" & a$period == "TTM" & a$end == end],
                 a$val[a$metric == "revenue" & a$period == "FY"  & a$end == end])
})
