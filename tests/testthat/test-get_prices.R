test_that("get_prices returns date, close and split_factor", {
    local_mock_quantmod()
    p <- get_prices("ABC")
    expect_identical(
        vapply(p, function(x) class(x)[1], character(1)),
        c(date = "Date", close = "numeric", split_factor = "numeric"))
})

test_that("get_prices factors in only splits after each date", {
    local_mock_quantmod()
    p <- get_prices("ABC")
    expect_identical(p$split_factor, c(0.1, 0.1, 1, 1))
})

test_that("get_prices drops days with no close", {
    local_mock_quantmod()
    p <- get_prices("ABC")
    expect_identical(p$date, as.Date(c("2024-06-06", "2024-06-07", "2024-06-10", "2024-06-11")))
    expect_identical(p$close, c(10, 11, 12, 13))
})

test_that("get_prices uses a factor of 1 when there are no splits", {
    local_mock_quantmod(make_no_splits())
    p <- get_prices("ABC")
    expect_identical(p$split_factor, rep(1, 4))
})

test_that("get_prices passes ticker and from to quantmod", {
    calls <- local_mock_quantmod()
    get_prices("ABC", from = "2024-06-06")
    expect_identical(calls$getSymbols,
        list(Symbols = "ABC", src = "yahoo", from = "2024-06-06", auto.assign = FALSE))
    expect_identical(calls$getSplits, list(Symbol = "ABC"))
})

test_that("get_prices AT&T live: WarnerMedia spin-off is recorded as a split", {
    skip_on_cran()
    skip_if_offline("query1.finance.yahoo.com")
    p <- get_prices("T", from = "2022-04-01")
    f <- setNames(p$split_factor, as.character(p$date))
    expect_equal(f[["2022-04-08"]], 0.755287, tolerance = 1e-5)
    expect_identical(f[["2022-04-11"]], 1)
})
