test_that("company_ratios output shape is correct", {
    r <- company_ratios(make_ratio_history())
    expect_identical(
        vapply(r, function(x) class(x)[1], character(1)),
        c(ratio = "character", period = "character", start = "Date", end = "Date",
          val = "numeric", filed = "Date", first_filed = "Date"))
    expect_identical(nrow(r), 12L)
})

test_that("company_ratios calculations are correct", {
    r <- company_ratios(make_ratio_history())
    fy <- dplyr::filter(r, period == "FY", ratio %in% c("operating_margin", "net_margin",
            "fcf_margin", "interest_coverage", "payout_ratio", "dividend_fcf_coverage"))
    expect_equal(setNames(fy$val, fy$ratio),
        c(dividend_fcf_coverage = 2.5, fcf_margin = 0.2, interest_coverage = 5,
          net_margin = 0.12, operating_margin = 0.2, payout_ratio = 80 / 120))
})

test_that("company_ratios calculates debt_to_equity correctly", {
    r <- company_ratios(make_ratio_history())
    expect_equal(
        dplyr::filter(r, ratio == "debt_to_equity") |>
        dplyr::select(period, start, val),
        tibble::tibble(period = "instant", start = as.Date(NA_character_), val = 1))
})

test_that("company_ratios mixed ratios", {
    r <- company_ratios(make_ratio_history())
    fy <- dplyr::filter(r, period == "FY", ratio %in% c("roe", "roic",
            "net_debt_to_ebitda"), start == as.Date("2025-01-01"))
    expect_equal(setNames(fy$val, fy$ratio),
        c(net_debt_to_ebitda = 1.2, roe = 0.24, roic = 0.2))
})

test_that("company_ratios no mixed ratio has a Q row", {
    r <- company_ratios(make_ratio_history())
    expect_identical(nrow(dplyr::filter(r, ratio %in% c("roe", "roic",
                     "net_debt_to_ebitda"), period == "Q")), 0L)
})

test_that("company_ratios division by zero is dropped", {
    r <- company_ratios(make_ratio_history())
    expect_identical(nrow(dplyr::filter(r, ratio == "interest_coverage", period == "Q")), 0L)
    expect_equal(dplyr::filter(r, ratio == "operating_margin", period == "Q")$val, 0.2)
})

test_that("company_ratios filing dates", {
    r <- company_ratios(make_ratio_history())
    expect_identical(dplyr::filter(r, ratio %in% c("roe", "debt_to_equity"),
                                   period %in% c("FY", "instant")) |>
        dplyr::select(filed, first_filed),
        tibble::tibble(filed = c(as.Date("2026-03-01"), as.Date("2026-03-01")),
                       first_filed = c(as.Date("2026-02-15"), as.Date("2026-02-15"))))
})

test_that("company_ratios only ratios come out", {
    r <- company_ratios(make_ratio_history())
    expect_identical(sort(unique(r$ratio)),
        sort(c("operating_margin", "net_margin", "fcf_margin", "interest_coverage",
               "payout_ratio", "dividend_fcf_coverage", "debt_to_equity",
               "net_debt_to_ebitda", "roe", "roic")))
})

test_that("company_ratios AT&T Live test", {
    skip_on_cran()
    skip_if_offline("www.sec.gov")
    ua <- Sys.getenv("SEC_USERAGENT")
    skip_if(ua == "", "SEC_USERAGENT not set")
    r <- company_ratios(suppressMessages(company_history("732717", ua, withr::local_tempdir())))
    end <- as.Date("2023-12-31")
    expect_equal(r$val[r$ratio == "operating_margin" & r$period == "TTM" & r$end == end],
                 r$val[r$ratio == "operating_margin" & r$period == "FY"  & r$end == end])
})
