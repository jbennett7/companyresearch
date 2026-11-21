test_that("resolve_metrics has the correct shape", {
    rm <- resolve_metrics(make_facts())
    expect_identical(
        vapply(rm, function(x) class(x)[1], character(1)),
        c(metric = "character", tag = "character", start = "Date", end = "Date",
          val = "numeric", accn = "character", form = "character", filed = "Date",
          first_filed = "Date"))
    expect_equal(nrow(rm), 5)
})

test_that("resolve_metrics priority within a period is enforced", {
    rm <- resolve_metrics(make_facts())
    result <- dplyr::filter(rm, metric == "interest_expense", end == as.Date("2025-03-31"))
    expect_identical(result$tag, "InterestExpenseNonoperating")
})

test_that("resolve_metrics fallback by period", {
    rm <- resolve_metrics(make_facts())
    result <- dplyr::filter(rm, metric == "interest_expense", end == as.Date("2024-03-31"))
    expect_identical(result$tag, "InterestExpense")
    expect_equal(result$val, 90)
})

test_that("resolve_metrics restatement", {
    rm <- resolve_metrics(make_facts())
    result <- dplyr::filter(rm, metric == "revenue", end == as.Date("2024-12-31"))
    expect_equal(result$val, 1010)
    expect_identical(result$filed, as.Date("2026-02-15"))
    expect_identical(result$first_filed, as.Date("2025-02-15"))
})

test_that("resolve_metrics priority beats recency", {
    rm <- resolve_metrics(make_facts())
    result <- dplyr::filter(rm, metric == "revenue", start == as.Date("2025-01-01"))
    expect_identical(result$tag, "Revenues")
    expect_equal(result$val, 1200)
})

test_that("resolve_metrics instant duplicates collapse", {
    rm <- resolve_metrics(make_facts())
    result <- dplyr::filter(rm, metric == "total_assets")
    expect_identical(result, 
        tibble::tibble(metric = "total_assets", tag = "Assets", start = as.Date(NA_character_),
                       end = as.Date("2024-12-31"), val = 5000, accn = "D", form = "10-K",
                       filed = as.Date("2026-02-15"), first_filed = as.Date("2025-02-15")))
})

test_that("resolve_metrics traps are ignored", {
    rm <- resolve_metrics(make_facts())
    expect_equal(nrow(rm[rm$end == as.Date("2023-12-31"), ]), 0)
    expect_true(all(rm$metric %in% metric_map()$metric))
    expect_false("GrossProfit" %in% rm$tag)
})

test_that("resolve_metrics map override", {
    map <- metric_map()
    map$priority[map$tag == "InterestExpenseNonoperating"] <- 2L
    map$priority[map$tag == "InterestExpense"] <- 1L
    rm <- resolve_metrics(make_facts(), map)
    result <- dplyr::filter(rm, metric == "interest_expense",
                            end == as.Date("2025-03-31"))
    expect_identical(result$tag, "InterestExpense")
})
