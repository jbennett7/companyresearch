#' Daily closing prices and split factors
#'
#' Downloads daily closes from Yahoo Finance with quantmod, along with the
#' stock's split history. Requires network access.
#'
#' `close` is split-adjusted: every close is on today's share basis.
#' `split_factor` is the product of the split ratios (old shares / new shares)
#' for splits after `date`, or 1 if there are none. Dividing `close` by
#' `split_factor` gives the price as quoted on that day.
#'
#' Yahoo records some spin-offs as splits. For example, AT&T's 2022-04-11
#' WarnerMedia spin-off appears as a 0.755 split, so AT&T closes before that
#' date are scaled down by the spin-off value.
#'
#' @param ticker Stock symbol, e.g. `"T"`
#' @param from First date to download, as `"YYYY-MM-DD"`
#'
#' @return A tibble with one row per trading day with a close: `date`,
#'   `close` and `split_factor`
#'
#' @examples
#' \dontrun{
#' get_prices("T", from = "2022-01-01")
#' }
#' @export
get_prices <- function(ticker, from = "2000-01-01") {
    x <- quantmod::getSymbols(ticker, src = "yahoo", from = from, auto.assign = FALSE)
    s <- quantmod::getSplits(ticker)
    prices <- tibble::tibble(date  = as.Date(as.numeric(zoo::index(x))),
                             close = as.numeric(quantmod::Cl(x)))
    prices <- prices[!is.na(prices$close), ]
    splits <- tibble::tibble(date = zoo::index(s), ratio = as.numeric(s))
    prices$split_factor <- vapply(prices$date,
        function(d) prod(splits$ratio[splits$date > d]), numeric(1))
    prices
}
