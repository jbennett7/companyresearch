suppressMessages({
    devtools::load_all('../xbrlstatements')
    devtools::load_all('../secfilings')
    library(tibble)
    library(stringr)
    library(dplyr)
    library(XBRL)
    library(ggplot2)
    library(purrr)
    library(tidyr)
})

useragent <- Sys.getenv("SEC_USERAGENT")
ticker    <- "T"
cik       <- get_cik(ticker, useragent)

label_for <- function(elt, preferred_role) {
    cand <- labels |> filter(elementId == elt)
    hit <- cand |> filter(labelRole == preferred_role)
    if (nrow(hit) == 0)
        hit <- cand |> filter(labelRole == "http://www.xbrl.org/2003/role/label")
    if (nrow(hit) == 0) return(elt)
    hit$labelString[1]
}

flatten <- function(id, depth, preferred_role, seq_env) {
    is_struct <- elements$structural[match(id, elements$elementId)]
    is_struct <- isTRUE(is_struct)
    row <- NULL
    if (!is_struct) {
        seq_env$n <- seq_env$n + 1
        row <- tibble(seq = seq_env$n, elementId = id, depth = depth,
                      negated = grepl("negated", preferred_role %||% ""),
                      label = label_for(id, preferred_role %||%
                                        "http://www.xbrl.org/2003/role/label"))
    }
    next_depth <- if (is_struct) depth else depth + 1
    kids <- pres |> filter(fromElementId == id) |> arrange(order)
    child_rows <- pmap(list(kids$toElementId, kids$preferredLabel),
                       \(cid, plabel) flatten(cid, next_depth, plabel, seq_env))
    bind_rows(row, bind_rows(child_rows))
}

`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

filings <- get_submissions(cik, useragent) |>
    filter(
        grepl("^10-[KQ](?:\\/A)?$", form),
        reportDate > as.Date("2022-12-31"),
        isXBRL == 1) |>
    arrange(desc(reportDate))

print(filings$form)

xbrl <- process_filing(cik, filings$accessionNumber[1], useragent)

bs_role_id <- xbrl$role |>
    filter(
        type == 'Statement',
        grepl('balance sheets?(?: \\(Unaudited\\))?$',
              ignore.case=TRUE, description)) |>
    pull(roleId)
stopifnot(length(bs_role_id) == 1)

pres <- xbrl$presentation |>
    filter(roleId == bs_role_id) |>
    select(fromElementId, toElementId, order, preferredLabel) |>
    mutate(order = as.numeric(order))

elements <- xbrl$element |>
    select(elementId, type, substitutionGroup, abstract) |>
    mutate(structural = substitutionGroup %in%
           c("xbrldt:hypercubeItem", "xbrldt:dimensionItem") |
           type == "dtr-types:domainItemType")

labels <- xbrl$label |>
    select(elementId, labelRole, labelString)

root <- setdiff(pres$fromElementId, pres$toElementId)
stopifnot(length(root) == 1)

seq_env <- new.env()
seq_env$n <- 0L
statement <- flatten(root, depth = 0, preferred_role = NA, seq_env = seq_env)
statement <- statement |> filter(elementId != root)
elt_ids <- unique(statement$elementId)

values <- xbrl$fact |>
    filter(elementId %in% elt_ids) |>
    inner_join(xbrl$context |> filter(instant), by="contextId") |>
    anti_join(xbrl$dimension, by="contextId") |>
    distinct(elementId, endDate, fact, decimals) |>
    mutate(fact = as.numeric(fact),
           precision = if_else(decimals == "INF", Inf,
                               suppressWarnings(as.numeric(decimals)))) |>
    group_by(elementId, endDate) |>
    slice_max(precision, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(-decimals, -precision)

date_cols <- head(sort(unique(values$endDate), decreasing = TRUE), 2)
values <- values |> filter(endDate %in% date_cols)

wide <- values |>
    pivot_wider(names_from = endDate, values_from = fact) |>
    select(elementId, all_of(date_cols))

balance_sheet <- statement |>
    left_join(wide, by = "elementId") |>
    arrange(seq) |>
    mutate(across(all_of(date_cols), ~ if_else(negated, -.x, .x))) |>
    mutate(display_label = paste0(strrep("    ", depth), label)) |>
    select(display_label, all_of(date_cols))

#print(balance_sheet, n = Inf)

descendants <- function(id, pres) {
    kids <- pres$toElementId[pres$fromElementId == id]
    c(kids, unlist(lapply(kids, descendants, pres = pres)))
}

list_assets <- function(statement, pres, wide, date_cols,
                        elements = NULL, include_headers = TRUE) {
    total <- "us-gaap_Assets"
    if (!total %in% statement$elementId)
        stop("No us-gaap_Assets total found on this statement")

    parent <- pres$fromElementId[pres$toElementId == total][1]
    roots  <- setdiff(pres$fromElementId, pres$toElementId)

    assets <- if (parent %in% roots) {
        # no "Assets" header node -> take everything through the Total Assets line
        statement |> filter(seq <= seq[elementId == total][1])
    } else {
        ids <- c(parent, descendants(parent, pres))
        statement |> filter(elementId %in% ids)
    }

    if (!include_headers && !is.null(elements)) {
        abstract_ids <- elements$elementId[elements$abstract %in% c("true", TRUE)]
        assets <- assets |> filter(!elementId %in% abstract_ids)
    }

    assets |>
        mutate(depth = depth - min(depth)) |>
        left_join(wide, by = "elementId") |>
        arrange(seq) |>
        mutate(across(all_of(date_cols), ~ if_else(negated, -.x, .x)),
               display_label = paste0(strrep("    ", depth), label)) |>
        select(elementId, display_label, all_of(date_cols))
}
#list_assets(statement, pres, wide, date_cols, elements, include_headers = FALSE) |> print(n=Inf)

list_liabilities <- function(statement, pres, wide, date_cols,
                        elements = NULL, include_headers = TRUE) {
    total <- "us-gaap_Liabilities"
    if (!total %in% statement$elementId)
        stop("No us-gaap_Liabilities total found on this statement")

    parent <- pres$fromElementId[pres$toElementId == total][1]
    roots  <- setdiff(pres$fromElementId, pres$toElementId)

    assets <- if (parent %in% roots) {
        # no "Liabilities" header node -> take everything through the Total Assets line
        statement |> filter(seq <= seq[elementId == total][1])
    } else {
        ids <- c(parent, descendants(parent, pres))
        statement |> filter(elementId %in% ids)
    }

    if (!include_headers && !is.null(elements)) {
        abstract_ids <- elements$elementId[elements$abstract %in% c("true", TRUE)]
        assets <- assets |> filter(!elementId %in% abstract_ids)
    }

    assets |>
        mutate(depth = depth - min(depth)) |>
        left_join(wide, by = "elementId") |>
        arrange(seq) |>
        mutate(across(all_of(date_cols), ~ if_else(negated, -.x, .x)),
               display_label = paste0(strrep("    ", depth), label)) |>
        select(elementId, display_label, all_of(date_cols))
}
#list_liabilities(statement, pres, wide, date_cols, elements, include_headers = FALSE)


fact_status <- function(xbrl) {
    all_ids    <- unique(xbrl$fact$elementId)
    consol_ids <- xbrl$fact |>
        anti_join(xbrl$dimension, by = "contextId") |>
        pull(elementId) |> unique()
    status <- setNames(rep("d", length(all_ids)), all_ids)  # dimensional only
    status[consol_ids] <- "*"                               # has a consolidated fact
    status
}

print_tree <- function(id, pres, elements, depth = 0, plabel = NA, facts = NULL) {
    el   <- elements[match(id, elements$elementId),]
    tag  <- if (isTRUE(el$structural)) "[S]"
            else if (isTRUE(el$abstract %in% c("true", TRUE))) "[A]"
            else "   "
    mark <- if (is.null(facts)) "" else (facts[id] %|NA|% " ")
    role <- if (is.na(plabel)) "" else paste0("  <", basename(plabel), ">")
    cat(sprintf("%s %s %s%s%s\n", tag, mark, strrep("  ", depth), id, role))

    kids <- pres |> filter(fromElementId == id) |> arrange(order)
    for (i in seq_len(nrow(kids)))
        print_tree(kids$toElementId[i], pres, elements, depth + 1,
                   kids$preferredLabel[i], facts)
}

`%|NA|%` <- function(a, b) if (is.na(a)) b else a

#facts <- fact_status(xbrl)
#root <- setdiff(pres$fromElementId, pres$toElementId)
#for (r in root) print_tree(r, pres, elements, facts = facts)
