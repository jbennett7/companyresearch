test_that("derive_quarters has the correct shape", {
    h <- derive_quarters(make_resolved())
    # metric period start  end    val   source tag   filed
    # <chr>  <chr>  <date> <date> <dbl> <chr>  <chr> <date>
    expect_identical(
        vapply(h, function(x) class(x)[1], character(1)),
        c(metric = "character", period = "character", start = "Date", end = "Date",
          val = "numeric", source = "character", tag = "character",
          filed = "Date", first_filed = "Date"))
    expect_identical(nrow(h), 11L)
})

test_that("derive_quarters reported quarters stay reported", {
    # revenue Q1 (ending 2025-03-31, 100) and interest
    h <- derive_quarters(make_resolved())
    expect_identical(dplyr::bind_rows(
        h |> dplyr::filter(metric == "revenue", period == "Q", end == as.Date("2025-03-31")),
        h |> dplyr::filter(metric == "interest_expense", period == "Q",
                           end == as.Date("2024-03-31"))) |> dplyr::pull(source),
        c("reported", "reported"))
})

test_that("derive_quarters q3 is derived from 9M - 6M", {
    # revenue with `Q` period, ending in 2025-09-30 has the following values
    expect_identical(derive_quarters(make_resolved()) |>
        dplyr::filter(metric == "revenue", period == "Q", end == as.Date("2025-09-30")) |>
        dplyr::select(val, start, source),
        tibble::tibble(val = 118, start = as.Date("2025-07-01"), source = "derived"))
})

test_that("derive_quarters q4 is derived from FY - 9M", {
    # revenue with `Q` period, ending in 2025-12-31 has the following values
    expect_identical(derive_quarters(make_resolved()) |>
        dplyr::filter(metric == "revenue", period == "Q", end == as.Date("2025-12-31")) |>
        dplyr::select(val, start, source),
        tibble::tibble(val = 130, start = as.Date("2025-10-01"), source = "derived"))
})

test_that("derive_quarters reported beats derived", {
    # revenue has only one `Q` period ending in 2025-06-30 with following values
    expect_identical(derive_quarters(make_resolved()) |>
        dplyr::filter(metric == "revenue", period == "Q", end == as.Date("2025-06-30")) |>
        dplyr::select(val, source, start),
        tibble::tibble(val = 110, source = "reported", start = as.Date("2025-04-01")))
})

test_that("derive_quarters gaps stay gaps", {
    # interest has no `Q` periods ending in 2024-06-30 or 2024-09-30
    h <- derive_quarters(make_resolved()) |>
        dplyr::filter(metric == "interest_expense")
    # no Q ending 2024-06-30 or 2024-09-30 (no 6M to pair with)
    expect_identical(
        nrow(dplyr::filter(h, end %in% as.Date(c("2024-06-30", "2024-09-30")))), 0L)
    # Q4 is still derived from FY - 9M
    expect_identical(h |>
        dplyr::filter(period == "Q", end == as.Date("2024-12-31")) |>
        dplyr::select(val, start, source),
        tibble::tibble(val = 60, start = as.Date("2024-10-01"), source = "derived"))
})

test_that("derive_quarters non-additive metrics are never derived", {
    h <- derive_quarters(make_resolved())
    # no `eps_diluted` has `source == "derived"`
    expect_identical(nrow(h |> dplyr::filter(metric == "eps_diluted", source == "derived")), 0L)
    # eps has exactly 2 rows: Q1 0.5 and FY 2.3
    expect_identical(h |> dplyr::filter(metric == "eps_diluted"),
        tibble::tibble(metric = c("eps_diluted", "eps_diluted"), period = c("Q", "FY"),
                       start = as.Date(c("2025-01-01", "2025-01-01")),
                       end = as.Date(c("2025-03-31", "2025-12-31")), val = c(0.5, 2.3),
                       source = c("reported", "reported"),
                       tag = c("EarningsPerShareDiluted", "EarningsPerShareDiluted"),
                       filed = as.Date(c("2025-05-01", "2026-02-15")),
                       first_filed = as.Date(c("2025-05-01", "2026-02-15"))))
})

test_that("derive_quarters instants pass through", {
    # one `total_assets` row, with `period == "instant"`, NA `start`,
    # `val` 5000 and `source == "reported"`
    expect_identical(derive_quarters(make_resolved()) |>
                     dplyr::filter(metric == "total_assets"),
        tibble::tibble(metric = "total_assets", period = "instant", 
                       start = as.Date(NA_character_), end = as.Date("2025-12-31"),
                       val = 5000, source = "reported", tag = "Assets",
                       filed = as.Date("2026-02-15"),
                       first_filed = as.Date("2026-02-15")))
})

test_that("derive_quarters output contains no year-to-date or stub rows", {
    h <- derive_quarters(make_resolved())
    # period
    expect_in(h$period, c("Q", "FY", "instant"))
    # no row has end 2023-12-31 (the stub)
    expect_identical(nrow(h |> dplyr::filter(end == as.Date("2023-12-31"))), 0L)
    # the revenue 6M and 9M values (212 and 330) aren't in `val`
    expect_identical(nrow(h |> dplyr::filter(metric == "revenue", val %in% c(212, 330))), 0L)
})

test_that("derive_quarters derived rows take their dates from the later row", {
    h <- derive_quarters(make_resolved())
    # revenue Q4 has `filed` and `first_filed` of 2026-02-15 (the 10-K)
    expect_identical(dplyr::filter(h, metric == "revenue", period == "Q",
                                   end == as.Date("2025-12-31")) |>
                     dplyr::select(filed, first_filed),
                     tibble::tibble(filed = as.Date("2026-02-15"),
                                    first_filed = as.Date("2026-02-15")))
    # revenue Q3 has 2025-11-01
    expect_identical(dplyr::filter(h, metric == "revenue",
                                   period == "Q", end == as.Date("2025-09-30")) |>
                     dplyr::select(filed, first_filed),
                     tibble::tibble(filed = as.Date("2025-11-01"),
                                    first_filed = as.Date("2025-11-01")))

})

test_that("Live AT&T check", {
    skip_on_cran()
    skip_if_offline("www.sec.gov");
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_if(ua == "", "SEC_USERAGENT not set")
    suppressMessages({
        cf <- secfilings::get_companyfacts("732717", ua, withr::local_tempdir())
    })
    h <- derive_quarters(resolve_metrics(cf))
    q <- dplyr::filter(h, metric == "interest_expense", period == "Q",
                       end >= as.Date("2023-03-31"), end <= as.Date("2023-12-31"))
    expect_equal(q$val, c(1708, 1608, 1662, 1726) * 1e6)
    expect_identical(q$source, c("reported", "reported", "reported", "derived"))
})
