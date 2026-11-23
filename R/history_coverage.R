#' How complete a company's history is
#'
#' Summarises a history from [company_history()] by metric: how many
#' quarters, years and balance-sheet dates it has, how many quarters were
#' derived, where it starts and ends, how many quarters are missing in
#' between, and which tags supplied the values.
#'
#' Every metric in the map gets a row, including metrics with no data. A
#' metric with no rows usually means the company reports it under a tag the
#' map doesn't list; add the tag with a modified [metric_map()]. A metric
#' whose `tags` lists several tags switched tags over time.
#'
#' Missing quarters are counted between the first and last quarter (or
#' balance-sheet date): each gap between consecutive dates counts as
#' `round(days / 91.3) - 1` missing quarters. Full-year rows are not counted.
#'
#' @param history A history from [company_history()].
#' @param map The metric map used to build `history`; defaults to
#'   [metric_map()].
#'
#' @return A tibble with one row per metric, in map order:
#'   \describe{
#'     \item{metric}{Metric name from the map.}
#'     \item{n_q, n_fy, n_instant}{Number of quarter, full-year and
#'       balance-sheet rows.}
#'     \item{n_derived}{Number of quarters derived from year-to-date values.}
#'     \item{first_end, last_end}{Earliest and latest period end; `NA` if the
#'       metric has no data.}
#'     \item{missing_q}{Number of quarters missing between `first_end` and
#'       `last_end`.}
#'     \item{tags}{Tags used, in order of first use, separated by `", "`;
#'       `NA` if the metric has no data.}
#'   }
#'
#' @examples
#' \dontrun{
#' h <- company_history("732717")
#' cov <- history_coverage(h)
#' dplyr::filter(cov, n_q + n_fy + n_instant == 0)  # metrics the map missed
#' }
#' @export
history_coverage <- function(history, map = metric_map()) {
    summary <- history |>
        dplyr::group_by(metric) |>
        dplyr::summarize(
            n_q        = sum(period == "Q"),
            n_fy       = sum(period == "FY"),
            n_instant  = sum(period == "instant"),
            n_derived  = sum(source == "derived"),
            first_end  = min(end),
            last_end   = max(end),
            missing_q  = {
                e <- sort(end[period %in% c("Q", "instant")])
                as.integer(sum(round(as.numeric(diff(e)) / 91.3) - 1))
            },
            tags       = paste(unique(tag[order(end)]), collapse = ", "),
            .groups = "drop")
        dplyr::left_join(dplyr::distinct(map, metric), summary, by = "metric") |>
            dplyr::mutate(dplyr::across(c(n_q, n_fy, n_instant, n_derived, missing_q),
                                        ~ dplyr::coalesce(.x, 0L)))
}
