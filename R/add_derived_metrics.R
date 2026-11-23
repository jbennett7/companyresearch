#' Combine two metrics into a new one, period by period
#'
#' @noRd
#' @param history a history tibble
#' @param name name of the new metric
#' @param a,b metric names of the two inputs
#' @param op function of two numeric vectors, e.g. `` `+` `` or `` `-` ``
#' @return rows for the new metric, in history layout
combine_metrics <- function(history, name, a, b, op) {
    x <- dplyr::filter(history, metric == a)
    y <- dplyr::filter(history, metric == b)
    dplyr::inner_join(x, y, by = c("period", "start", "end"),
                      suffix = c("_a", "_b")) |>
        dplyr::transmute(
            metric      = name,
            period, start, end,
            val         = op(val_a, val_b),
            source      = "computed",
            tag         = NA_character_,
            filed       = pmax(filed_a, filed_b),
            first_filed = pmax(first_filed_a, first_filed_b))
}

#' Add metrics computed from other metrics
#'
#' Adds fcf (operating cash flow - capex), ebitda (operating income + D&A),
#' total_debt (current + noncurrent debt) and net_debt (total debt - cash), for
#' each period where both inputs exist. Computed rows have source "computed",
#' no tag, and the later of the two inputs' filing dates.
#'
#' @noRd
#' @param history output from [company_history()]
#' @return `history` with the computed rows appended
add_derived_metrics <- function(history) {
    debt <- combine_metrics(history, "total_debt", "debt_current", "debt_noncurrent", `+`)
    history <- dplyr::bind_rows(history, debt)
    dplyr::bind_rows(
        history,
        combine_metrics(history, "net_debt", "total_debt", "cash", `-`),
        combine_metrics(history, "fcf", "operating_cash_flow", "capex", `-`),
        combine_metrics(history, "ebitda", "operating_income",
                        "depreciation_amortization", `+`))
}
