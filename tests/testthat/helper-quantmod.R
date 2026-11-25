local_mock_quantmod <- function(splits = make_splits(), env = parent.frame()) {
    calls <- new.env()
    local_mocked_bindings(
        getSymbols = function(Symbols, src, from, auto.assign) {
            calls$getSymbols <- list(Symbols = Symbols, src = src, from = from,
                                     auto.assign = auto.assign)
            make_symbols()
        },
        getSplits = function(Symbol, ...) {
            calls$getSplits <- list(Symbol = Symbol)
            splits
        },
        .package = "quantmod",
        .env = env)
    invisible(calls)
}

make_symbols <- function() {
    xts::xts(matrix(c(10, 11, 12, 13, NA_real_), dimnames = list(NULL, "ABC.Close")),
        order.by = as.Date(c("2024-06-06", "2024-06-07", "2024-06-10",
                             "2024-06-11", "2024-06-12")))
}

make_splits <- function() {
    xts::xts(matrix(c(0.25, 0.1), dimnames = list(NULL, "ABC.spl")),
        order.by = as.Date(c("2021-07-20", "2024-06-10")))
}

make_no_splits <- function() {
    xts::xts(numeric(0), order.by = as.Date(character(0)))
}

make_market_prices <- function() {
    tibble::tribble(
        ~date, ~close, ~split_factor,
        "2023-12-29", 9, 0.5,
        "2024-01-30", 9.5, 0.5,
        "2024-01-31", 10, 0.5,
        "2024-02-29", 11, 0.5,
        "2024-03-01", 11.5, 1,
        "2024-03-28", 12, 1,
        "2024-04-30", 13, 1
    ) |>
    dplyr::mutate(date = as.Date(date))
}
