#' Reduce one instant metric to the rows an as-of join can use.
#'
#' @noRd
#' @param history a history in the standard layout
#' @param name a single metric name
latest_known <- function(history, name) {
    dplyr::filter(history, metric == name, period == "instant") |>
        dplyr::group_by(first_filed) |>
        dplyr::slice_max(end, n = 1) |>
        dplyr::ungroup() |>
        dplyr::transmute(end = end, val = val, known = first_filed)
}

#' A monthly series of market cap and enterprise value.
#'
#' Using only the share count and net debt that had been filed by each month end.
#'
#' It is a known limitation that Yahoo records some spin-offs as splits. From a
#' spin-off until the next filing's share count, `shares` is inflated by the
#' spin-off ratio, so market cap is overstated. For AT&T this is about 32% in
#' April-May 2022. It corrects itself at the next filing.
#'
#' @noRd
#' @param history the history plus `add_derived_metrics()`
#' @param prices the output of [get_prices()]
#' @return A tibble with the following variables: `date`, `close`, `shares`,
#'     `market_cap`, `net_debt`, `enterprise_value`, `shares_end`, `net_debt_end`
market_values <- function(history, prices) {
    shares_tbl <- latest_known(history, "shares_outstanding") |>
        dplyr::left_join(dplyr::select(prices, price_date = date, split_factor),
            dplyr::join_by(closest(end >= price_date))) |>
        dplyr::transmute(shares_end = end, shares = val / split_factor,
                         shares_known = known)

    debt_tbl <- latest_known(history, "net_debt") |>
        dplyr::transmute(net_debt_end = end, net_debt = val, net_debt_known = known)

    dplyr::group_by(prices, month = format(date, "%Y-%m")) |>
    dplyr::slice_max(date, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(-month) |>
    dplyr::left_join(shares_tbl, dplyr::join_by(closest(date >= shares_known))) |>
    dplyr::left_join(debt_tbl, dplyr::join_by(closest(date >= net_debt_known))) |>
    dplyr::filter(!is.na(shares)) |>
    dplyr::mutate(market_cap = close * shares, enterprise_value = market_cap + net_debt) |>
    dplyr::select(date, close, shares, market_cap, net_debt, enterprise_value, shares_end,
                  net_debt_end)
}
