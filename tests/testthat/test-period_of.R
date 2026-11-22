test_that("period_of successfully translates for typical date cases", {
    expect_identical(period_of(as.Date("2026-01-01"), as.Date("2026-03-31")), "3M")
    expect_identical(period_of(as.Date("2026-01-01"), as.Date("2026-06-30")), "6M")
    expect_identical(period_of(as.Date("2026-01-01"), as.Date("2026-09-30")), "9M")
    expect_identical(period_of(as.Date("2026-01-01"), as.Date("2026-12-31")), "FY")
    expect_identical(period_of(as.Date(NA_character_), as.Date("2026-12-31")), "instant")
})

test_that("period_of successfully translates for calendar edge cases", {
    # leap year (366 days)
    expect_identical(period_of(as.Date("2024-01-01"), as.Date("2024-12-31")), "FY")
    # February-only quarters (90 days)
    expect_identical(period_of(as.Date("2025-01-01"), as.Date("2025-03-31")), "3M")
    # a quarter ending Sep 30 that starts Jul 1 (92 days)
    expect_identical(period_of(as.Date("2026-07-01"), as.Date("2026-09-30")), "3M")
})

test_that("period_of 52/53-week years", {
    start <- as.Date("2024-01-01")
    # 363 days
    expect_identical(period_of(start, start+362), "FY")
    # A 53-week year of 371 days
    expect_identical(period_of(start, start+370), "FY")
})

test_that("period_of unusual periods give other", {
    start <- as.Date("2024-01-01")
    # 112 days 16-week quarter
    expect_identical(period_of(start, start+111), "other")
    # 60 days
    expect_identical(period_of(start, start+59), "other")
})

test_that("period_of is vectorized and handles NA starts in a mixed vector", {
    start <- as.Date(c(rep("2025-01-01", 4), NA_character_, "2025-01-01"))
    end   <- as.Date(c("2025-03-31", "2025-06-30", "2025-09-30",
                       "2025-12-31", "2025-12-31", "2026-02-28"))
    expect_identical(period_of(start, end),
                     c("3M", "6M", "9M", "FY", "instant", "other"))
})

test_that("period_of every range boundary", {
    start <- as.Date("2024-01-01")
    days <- c(76, 77, 105, 106, 167, 168, 196, 197, 258, 259, 287, 288, 349, 350, 378, 379)
    expect_identical(
        period_of(rep(start, length(days)), start + days - 1),
        c("other", "3M", "3M", "other", "other", "6M", "6M", "other",
          "other", "9M", "9M", "other", "other", "FY", "FY", "other"))
})
