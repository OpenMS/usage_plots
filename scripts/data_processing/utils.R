# Rows of the tables per period: each full year from FIRST_YEAR on, the fourth quarter of the previous year to
# the third quarter of the current year, and the current year.
# First_Day and Last_Day are the dates that the periods span.
get_quarter_ranges <- function()
{
  current_year <- CURRENT_YEAR
  previous_year <- current_year - 1
  full_years <- if (previous_year >= FIRST_YEAR) FIRST_YEAR:previous_year else integer(0)

  data.frame(
    Start = c(paste(full_years, "Q1"),
              paste(previous_year, "Q4"),
              paste(current_year, "Q1")),
    Start_as_Date = c(full_years + 0.1,
                      previous_year + 0.4,
                      current_year + 0.1),
    End = c(paste(full_years, "Q4"),
            paste(current_year, "Q3"),
            paste(current_year, "Q4")),
    End_as_Date = c(full_years + 0.4,
                    current_year + 0.3,
                    current_year + 0.4),
    First_Day = as.Date(c(paste0(full_years, "-01-01"),
                          paste0(previous_year, "-10-01"),
                          paste0(current_year, "-01-01"))),
    Last_Day = as.Date(c(paste0(full_years, "-12-31"),
                         paste0(current_year, "-09-30"),
                         paste0(current_year, "-12-31"))),
    stringsAsFactors = FALSE
  )
}

# Markdown heading of the tab that shows `view`
tab_heading <- function(view, tabset = FALSE)
{
  return(paste0("### ", view$label, if (tabset) " {.tabset}" else "", "\n\n"))
}

saveTable <- function(name, table)
{
    table_basename_tsv <- paste0(name, CURRENT_DATE, ".tsv")
    table_output_tsv <- paste(output_dir, table_basename_tsv, sep = "/")
    write.table(table, sep = "\t", file = table_output_tsv, row.names = FALSE)
    result <- list(data = table,
                   tsv = list(basename = table_basename_tsv,
                              absolute = table_output_tsv))
    return(result)
}


TABLE_CLASS_COUNTER <- 0
display_table_with_buttons <- function(table_files) {
  col_names <- colnames(table_files$data)
  col_names <- sapply(col_names, function(col_name) gsub("_", " ", col_name))

  table_id <- paste0("DataTable_", TABLE_CLASS_COUNTER)
  TABLE_CLASS_COUNTER <<- TABLE_CLASS_COUNTER + 1

  table_html <- knitr::kable(table_files$data,
                             format.args = list(digits = 2, nsmall = 1, scientific = FALSE), # big.mark = "," breaks table sorting
                             table.attr = paste0("class=\"table table-condensed\" id=\"", table_id, "\""),
                             format = "html",
                             col.names = col_names) %>%
                   row_spec(row=0, align="center")

  buttons_html <- paste0('<a href="', table_files$tsv$basename, '" download class="btn btn-info btn-dl" target="_blank">TSV</a> ')

  numeric_columns <- unname(which(sapply(table_files$data, is.numeric))) - 1
  numeric_columns <- paste0("[", paste0(numeric_columns, collapse = ","), "]")
  script_html <- paste0(
    '<script>\n',
      'const ', table_id, r"( = new simpleDatatables.DataTable("#)", table_id, r"(", {)",
        'searchable: true, ',
        'perPage: 10, ',
        'columns : [ { ',
          'select: ', numeric_columns, ', ',
          r"(type: "number", )",
          r"(render: function(data, td, rowIndex, cellIndex) { return Number(`${data}`).toLocaleString("en-US"); })",
      ' } ] } );\n',
    '</script>\n')

  return(paste0(table_html, "\n\n", buttons_html, "\n\n", script_html))
}
