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

#' Combine a flow metric with a balance-sheet metric at the same period end
#'
#' Pairs fiscal-year and TTM rows of a flow metric (e.g. net income) with the
#' instant rows of a balance-sheet metric (e.g. equity) that share their `end`
#' date. Quarterly flows are left out, so ratios such as ROE are never computed
#' from a single quarter. The result takes `period` and `start` from the flow.
#'
#' @noRd
#' @param history a history tibble
#' @param name name of the new metric
#' @param flow metric name of flow input (FY and TTM rows are used)
#' @param balance metric name of the balance-sheet input (instant rows)
#' @param op called as `op(flow, balance)`; for balance / flow pass
#'     `function(f, b) b / f`
#' @return rows for the new metric, in history layout
combine_with_balance <- function(history, name, flow, balance, op){
    x <- dplyr::filter(history, metric == flow, period %in% c("FY", "TTM"))
    y <- dplyr::filter(history, metric == balance, period == "instant")
    dplyr::inner_join(x, y, by = "end", suffix = c("_a", "_b")) |>
        dplyr::transmute(
            metric = name, period = period_a, start = start_a, end,
            val = op(val_a, val_b), source = "computed", tag = NA_character_,
            filed = pmax(filed_a, filed_b),
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
