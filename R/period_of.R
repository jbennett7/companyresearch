#' Label a period by its length from start and end dates
#'
#' @noRd
#' @param start the start date as a date
#' @param end the end date as a date
#' @return a character string of "instant", "3M", "6M", "9M", "FY", "other"
period_of <- function(start, end) {
    days <- as.numeric(end - start) + 1
    dplyr::case_when(
        is.na(start)                   ~ "instant",
        dplyr::between(days, 77, 105)  ~ "3M",
        dplyr::between(days, 168, 196) ~ "6M",
        dplyr::between(days, 259, 287) ~ "9M",
        dplyr::between(days, 350, 378) ~ "FY",
        TRUE                          ~ "other")
}
