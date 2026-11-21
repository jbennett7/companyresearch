test_that("metric_map shape and types are correct", {
    map <- metric_map()
    expect_identical(
        vapply(map, typeof, character(1)),
        c(metric = "character", taxonomy = "character", tag = "character",
          priority = "integer", period_type = "character", unit = "character"))
})

test_that("metric_map only has valid period types", {
    map <- metric_map()
    expect_in(map$period_type, c("duration", "instant"))
})

test_that("metric_map priorities run 1...n per metric, with no gaps or repeats", {
    map <- metric_map()
    bad <- map |>
        dplyr::group_by(metric) |>
        dplyr::summarize(ok = identical(sort(priority), seq_len(dplyr::n()))) |>
        dplyr::filter(!ok)
    expect_identical(bad$metric, character(0))
})

test_that("metric_map each metric has only one period type and one unit", {
    map <- metric_map()
    bad <- map |>
        dplyr::group_by(metric) |>
        dplyr::summarize(
            n_period_type = dplyr::n_distinct(period_type),
            n_unit        = dplyr::n_distinct(unit)
        ) |>
        dplyr::filter(n_period_type > 1 | n_unit > 1)
    expect_identical(bad$metric, character(0))
})

test_that("metric_map no tag under two metrics", {
    map <- metric_map()
    expect_identical(map$tag[duplicated(map$tag)], character(0))
})

test_that("metric_map tags exist in real data (AT&T)", {
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_on_cran(); skip_if_offline("www.sec.gov"); skip_if(ua == "")
    cf <- secfilings::get_companyfacts("732717", ua, withr::local_tempdir())
    not_used_by_att <- c("SalesRevenueNet", "DepreciationAndAmortization",
                         "StockholdersEquity")
    expected <- setdiff(metric_map()$tag, not_used_by_att)
    expect_identical(setdiff(expected, unique(cf$tag)), character(0))
})
