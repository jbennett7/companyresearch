#' Build a quarterly and annual history from resolved metrics
#'
#' Keeps reported quarters, full years and instants. For additive metrics,
#' derives missing quarters from consecutive year-to-date values with the same
#' start (Q2 = 6M - 3M, Q3 = 9M - 6M, Q4 = FY - 9M); a reported quarter always
#' wins over a derived one.
#'
#' @noRd
#' @param resolved the output of `resolve_metrics()`
#' @param map the metric map
#' @return tibble of metric, period, start, end, val, source, tag, filed, first_filed
derive_quarters <- function(resolved, map = metric_map()) {
    x <- resolved |>
        dplyr::mutate(span = period_of(start, end)) |>
        dplyr::left_join(dplyr::distinct(map, metric, additive), by = "metric")

    instants <- x |>
        dplyr::filter(span == "instant") |>
        dplyr::mutate(period = "instant", source = "reported")

    fy <- x |>
        dplyr::filter(span == "FY") |>
        dplyr::mutate(period = "FY", source = "reported")

    reported_q <- x |>
        dplyr::filter(span == "3M") |>
        dplyr::mutate(period = "Q", source = "reported")

    derived <- x |>
        dplyr::filter(additive, span %in% c("3M", "6M", "9M", "FY")) |>
        dplyr::group_by(metric, start) |>
        dplyr::arrange(end, .by_group = TRUE) |>
        dplyr::mutate(prev_span = dplyr::lag(span),
                      prev_end  = dplyr::lag(end),
                      prev_val  = dplyr::lag(val)) |>
        dplyr::ungroup() |>
        dplyr::filter((prev_span == "3M" & span == "6M") |
                      (prev_span == "6M" & span == "9M") |
                      (prev_span == "9M" & span == "FY")) |>
        dplyr::mutate(start  = prev_end + 1,
                      val    = val - prev_val,
                      period = "Q",
                      source = "derived")

    derived <- dplyr::anti_join(derived, reported_q, by = c("metric", "end"))

    dplyr::bind_rows(instants, fy, reported_q, derived) |>
        dplyr::select(metric, period, start, end, val, source, tag, filed, first_filed) |>
        dplyr::arrange(metric, end, period)
}
