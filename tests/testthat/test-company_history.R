test_that("comapny_history runs the pipeline on the companyfacts", {
    local_mocked_bindings(
        get_companyfacts = function(cik, useragent, cache, refresh) make_facts(),
        .package = "secfilings")
    expect_identical(
        company_history("123", useragent = "ua"),
        derive_quarters(resolve_metrics(make_facts())))
})

test_that("company_history passes its arguments to get_companyfacts", {
    args <- NULL
    local_mocked_bindings(
        get_companyfacts = function(cik, useragent, cache, refresh) {
            args <<- list(cik = cik, useragent = useragent,
                          cache = cache, refresh = refresh)
            make_facts()
        },
        .package = "secfilings")
    company_history("123", useragent = "ua", cache = "x", refresh = TRUE)
    expect_identical(args,
        list(cik = "123", useragent = "ua", cache = "x", refresh = TRUE))
})

test_that("company_history test 3", {
    local_mocked_bindings(
        get_companyfacts = function(cik, useragent, cache, refresh) make_facts(),
        .package = "secfilings")
    one <- dplyr::filter(metric_map(), tag == "Assets")
    expect_identical(
        unique(company_history("123", useragent = "ua", map = one)$metric),
        "total_assets")
})

test_that("company_history empty useragent errors with \"SEC_USERAGENT\"", {
    local_mocked_bindings(
        get_companyfacts = function(cik, useragent, cache, refresh) stop("should not download"),
        .package = "secfilings")
    expect_error(company_history("123", useragent = ""), "SEC_USERAGENT")
})

test_that("company_history live AT&T test", {
    skip_on_cran()
    skip_if_offline("www.sec.gov");
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_if(ua == "", "SEC_USERAGENT not set")
    h <- company_history("732717", ua, withr::local_tempdir())
    q <- dplyr::filter(h, metric == "interest_expense", period == "Q",
                       end >= as.Date("2023-03-31"), end <= as.Date("2023-12-31"))
    expect_equal(q$val, c(1708, 1608, 1662, 1726) * 1e6)
    expect_identical(q$source, c("reported", "reported", "reported", "derived"))
})
