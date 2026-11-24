#' Add trailing-twelve-month rows
#'
#' For each additive metric, sums every run of four consecutive quarters (each
#' starting the day after the previous one ended) into a TTM row. Metrics the
#' map marks non-additive (EPS, average shares) get no TTM; metrics not in the
#' map (computed ones such as fcf) are treated as additive.
#'
#' @noRd
#' @param history usually after add_derived_metrics()
#' @param map the metric map used to build `history`
#' @return `history` with TTM rows appended (period "TTM", source "computed")
add_ttm <- function(history, map = metric_map()) {
    non_additive <- map$metric[!map$additive]

    ttm <- history |>
        dplyr::filter(period == "Q", !metric %in% non_additive) |>
        dplyr::group_by(metric) |>
        dplyr::arrange(end, .by_group = TRUE) |>
        dplyr::mutate(
            contig      = start == dplyr::lag(end) + 1,
            ok          = contig & dplyr::lag(contig) & dplyr::lag(contig, 2),
            val         = val + dplyr::lag(val) + dplyr::lag(val, 2) + dplyr::lag(val, 3),
            start       = dplyr::lag(start, 3),
            filed       = pmax(filed, dplyr::lag(filed), dplyr::lag(filed, 2),
                               dplyr::lag(filed, 3)),
            first_filed = pmax(first_filed, dplyr::lag(first_filed),
                               dplyr::lag(first_filed, 2), dplyr::lag(first_filed, 3))) |>
        dplyr::ungroup() |>
        dplyr::filter(ok) |>
        dplyr::mutate(period = "TTM", source = "computed", tag = NA_character_) |>
        dplyr::select(metric, period, start, end, val, source, tag, filed, first_filed)
    dplyr::bind_rows(history, ttm)
}
