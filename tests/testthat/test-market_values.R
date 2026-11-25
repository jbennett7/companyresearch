test_that("latest_known keeps the latest end when one filing reports two", {
    expect_identical(
        latest_known(make_market_history(), "net_debt"),
        tibble::tibble(end = as.Date("2023-12-31"), val = 500,
                       known = as.Date("2024-02-10")))
})

test_that("latest_known uses only instant rows", {
    expect_identical(
        nrow(latest_known(make_market_history(), "revenue")),
        0L)
})

test_that("market_values output shape is correct", {
    mv <- market_values(make_market_history(), make_market_prices())
    expect_identical(
        vapply(mv, function(x) class(x)[1], character(1)),
        c(date = "Date", close = "numeric", shares = "numeric",
          market_cap = "numeric", net_debt = "numeric",
          enterprise_value = "numeric", shares_end = "Date",
          net_debt_end = "Date"))
    expect_identical(nrow(mv), 4L)
})

test_that("market_values uses the last trading day of each month", {
    mv <- market_values(make_market_history(), make_market_prices())
    expect_identical(mv$date, as.Date(c("2024-01-31", "2024-02-29",
                                        "2024-03-28", "2024-04-30")))
})

test_that("market_values puts shares on today's split basis", {
    mv <- market_values(make_market_history(), make_market_prices())
    expect_equal(mv$shares, c(200, 200, 200, 210))
    expect_equal(mv$market_cap, c(2000, 2200, 2400, 2730))
})

test_that("market_values uses only values already filed by each month end", {
    mv <- market_values(make_market_history(), make_market_prices()) |>
        dplyr::filter(date == as.Date("2024-03-28"))
    expect_identical(mv$shares_end, as.Date("2024-01-20"))
    expect_equal(mv$shares, 200)
})

test_that("market_values keeps months with no net debt as NA", {
    mv <- market_values(make_market_history(), make_market_prices())
    expect_equal(mv$net_debt, c(NA, 500, 500, 500))
    expect_equal(mv$enterprise_value, c(NA, 2700, 2900, 3230))
    expect_identical(mv$net_debt_end,
                     as.Date(c(NA, "2023-12-31", "2023-12-31", "2023-12-31")))
})

test_that("market_values ignores other metrics", {
    mv <- market_values(make_market_history(), make_market_prices())
    h <- dplyr::filter(make_market_history(), metric != "revenue")
    expect_identical(mv, market_values(h, make_market_prices()))
})
