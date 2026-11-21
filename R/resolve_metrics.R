#' Resolve company facts to one value per metric per period
#'
#' Matches facts to the map on taxonomy, tag and unit. For each metric and
#' period, keeps the highest-priority tag, and within it the latest filing (so
#' restatements win). `first_filed` is the earliest filing that reported the
#' period, and for point-in-time use.
#'
#' @noRd
#' @param facts tibble from `secfilings::get_companyfacts()`
#' @param map metric map, default `metric_map()`
#' @return tibble with one row per metric and period: metric, tag, start,
#'   end, val, accn, form, filed, first_filed
resolve_metrics <- function(facts, map = metric_map()) {
    dplyr::inner_join(facts, map, by = c("taxonomy", "tag", "unit")) |>
        dplyr::group_by(metric, start, end) |>
        dplyr::mutate(first_filed = min(filed)) |>
        dplyr::arrange(priority, dplyr::desc(filed), .by_group = TRUE) |>
        dplyr::slice(1) |>
        dplyr::ungroup() |>
        dplyr::select(metric, tag, start, end, val, accn, form, filed, first_filed)
}
