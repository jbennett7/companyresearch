#' Financial health ratios for one company
#'
#' Computes margins, coverage, leverage and return ratios from a history built
#' by [company_history()], for quarters, fiscal years and trailing twelve
#' months (TTM). Free cash flow, EBITDA, total and net debt, and TTM values are
#' computed along the way.
#'
#' Ratios that combine a flow with a balance-sheet value (`roe`, `roic`,
#' `net_debt_to_ebitda`) use fiscal-year and TTM flows against the balance
#' sheet at the same period end; there are no quarterly versions. `roic` is an
#' approximation: NOPAT = operating income x (1 - income tax / (net income +
#' income tax)), invested capital = total debt + equity - cash. When equity
#' includes noncontrolling interest (see [metric_map()]), `roe` is understated.
#' Gross margin is not included. Ratios that divide by zero are dropped.
#'
#' @param history A history from [company_history()].
#' @param map The metric map used to build `history`; defaults to
#'   [metric_map()].
#'
#' @return A tibble with one row per ratio and period:
#'   \describe{
#'     \item{ratio}{`operating_margin`, `net_margin`, `fcf_margin`,
#'       `interest_coverage`, `payout_ratio`, `dividend_fcf_coverage`,
#'       `debt_to_equity`, `net_debt_to_ebitda`, `roe` or `roic`.}
#'     \item{period}{`"Q"`, `"FY"`, `"TTM"`, or `"instant"`
#'       (`debt_to_equity`).}
#'     \item{start, end}{Period dates; `start` is `NA` for instants.}
#'     \item{val}{The ratio, as a fraction (0.2 = 20 percent).}
#'     \item{filed, first_filed}{Latest filing and first filing among the
#'       inputs, i.e. when the ratio could first be computed.}
#'   }
#'
#' @examples
#' \dontrun{
#' h <- company_history("732717")
#' r <- company_ratios(h)
#' dplyr::filter(r, ratio == "roe", period == "FY")
#' }
#' @export
company_ratios <- function(history, map = metric_map()) {
    h <- add_ttm(add_derived_metrics(history), map)

    # ROIC inputs; each step is bound onto h so the next step can find it
    h <- dplyr::bind_rows(h,
        combine_metrics(h, "pretax", "net_income", "income_tax", `+`),
        combine_metrics(h, "debt_plus_equity", "total_debt", "equity", `+`))
    h <- dplyr::bind_rows(h,
        combine_metrics(h, "tax_rate", "income_tax", "pretax", `/`),
        combine_metrics(h, "invested_capital", "debt_plus_equity", "cash", `-`))
    h <- dplyr::bind_rows(h,
        combine_metrics(h, "nopat", "operating_income", "tax_rate",
                        function(a, b) a * (1 - b)))

    ratios <- dplyr::bind_rows(
        combine_metrics(h, "operating_margin", "operating_income", "revenue", `/`),
        combine_metrics(h, "net_margin", "net_income", "revenue", `/`),
        combine_metrics(h, "fcf_margin", "fcf", "revenue", `/`),
        combine_metrics(h, "interest_coverage", "operating_income", "interest_expense", `/`),
        combine_metrics(h, "payout_ratio", "dividends_paid", "net_income", `/`),
        combine_metrics(h, "dividend_fcf_coverage", "fcf", "dividends_paid", `/`),
        combine_metrics(h, "debt_to_equity", "total_debt", "equity", `/`),
        combine_with_balance(h, "net_debt_to_ebitda", "ebitda", "net_debt",
                             function(f, b) b / f),
        combine_with_balance(h, "roe", "net_income", "equity", `/`),
        combine_with_balance(h, "roic", "nopat", "invested_capital", `/`))

    ratios |>
        dplyr::filter(is.finite(val)) |>
        dplyr::select(ratio = metric, period, start, end, val, filed, first_filed) |>
        dplyr::arrange(ratio, end, period)
}
