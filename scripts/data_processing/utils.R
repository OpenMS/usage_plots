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
