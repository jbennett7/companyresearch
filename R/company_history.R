#' Quarterly and annual fundamentals history for one company
#'
#' Downloads (or reads from cache) a company's SEC companyfacts, picks one
#' value per metric and period using the metric map, and builds a history of
#' quarters, full years and balance-sheet instants. Quarters the company did
#' not report directly are derived from year-to-date values
#' (Q2 = 6M - 3M, Q3 = 9M - 6M, Q4 = FY - 9M) for additive metrics only.
#'
#' Only standard us-gaap tags are covered; company extension tags are not in
#' companyfacts. When a metric has several candidate tags, the highest-priority
#' tag reported for each period is used, so the tag can change over time (see
#' the `tag` column). Restated values replace earlier ones; `first_filed` keeps
#' the date the period was first reported.
#'
#' @param cik SEC Central Index Key, as a number or string, padded or not (e.g.
#'   `"732717"` for AT&T).
#' @param useragent User-Agent sent to the SEC, normally "Name email".
#'   Defaults to the `SEC_USERAGENT` environment variable.
#' @param cache Directory for cached downloads.
#' @param refresh If `TRUE`, download again even if a cached copy exists.
#' @param map Metric map; defaults to [metric_map()]. Pass a modified copy to
#'   add tags or change priorities for a particular company.
#'
#' @return A tibble with one row per metric and period:
#'   \describe{
#'     \item{metric}{Metric name from the map, e.g. `"revenue"`.}
#'     \item{period}{`"Q"` (quarter), `"FY"` (fiscal year) or `"instant"`
#'       (balance-sheet value at `end`).}
#'     \item{start, end}{Period dates; `start` is `NA` for instants.}
#'     \item{val}{Value in the metric's unit (USD, USD/shares or shares).}
#'     \item{source}{`"reported"` or `"derived"`.}
#'     \item{tag}{us-gaap tag the value came from; for derived quarters, the
#'       tag of the later year-to-date value.}
#'     \item{filed}{Filing date of the value used (the latest restatement).}
#'     \item{first_filed}{Date the period was first reported.}
#'  }
#'
#' @examples
#' \dontrun{
#' h <- company_history("732717")
#' dplyr::filter(h, metric == "revenue", period == "FY")
#' }
#' @export
company_history <- function(cik,
                            useragent = Sys.getenv("SEC_USERAGENT"),
                            cache = "./.cache",
                            refresh = FALSE,
                            map = metric_map()) {
    if (useragent == "") stop("useragent is empty; set SEC_USERAGENT")
    facts <- secfilings::get_companyfacts(cik, useragent, cache, refresh)
    derive_quarters(resolve_metrics(facts, map), map)
}
