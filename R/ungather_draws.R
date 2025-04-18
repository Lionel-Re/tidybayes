# ungather_draws
#
# Author: mjskay
###############################################################################

# Names that should be suppressed from global variable check by codetools
# Names used broadly should be put in _global_variables.R
globalVariables(c("..dimension_values"))


#' @importFrom tidyr spread
#' @rdname unspread_draws
#' @export
ungather_draws = function(
  data, ..., variable = ".variable", value = ".value", draw_indices = c(".chain", ".iteration", ".draw"), drop_indices = FALSE
) {
  draw_indices = intersect(draw_indices, names(data))
  variable_specs = enquos(...)

  if (length(variable_specs) == 0) {
    stop0("You must supply at least one variable to ungather.")
  }

  result =
    lapply(variable_specs, function(variable_spec) {
      ungather_draws_(data, variable_spec, variable = variable, value = value, draw_indices = draw_indices)
    }) %>%
    reduce_(inner_join, by = draw_indices, multiple = "all") %>%
    as_tibble()

  if (drop_indices) {
    result %>%
      select(-one_of(draw_indices))
  } else {
    result
  }
}

ungather_draws_ = function(
  data, variable_spec, variable = ".variable", value = ".value", draw_indices = c(".chain", ".iteration", ".draw")
) {

  #parse a variable spec in the form variable_name[dimension_name_1, dimension_name_2, ..] | wide_dimension
  spec = parse_variable_spec(variable_spec)
  variable_names = spec[[1]]
  dimension_names = spec[[2]]
  wide_dimension_name = spec[[3]]

  if (!is.null(wide_dimension_name)) {
    stop0("ungather_draws does not support the wide dimension syntax (`|`).")
  }

  # filter to desired rows and columns, removing duplicates (which may have been
  # introduced if `data` was the result of a call to `gather_variables`)
  data %<>%
    filter(.data[[variable]] %in% !!variable_names) %>%
    ungroup() %>%
    select_at(c(draw_indices, dimension_names, variable, value)) %>%
    distinct()

  if (is.null(dimension_names)) {
    return(spread(data, !!variable, !!value))
  }

  data %<>%
    unite(..dimension_values, !!!dimension_names, sep = ",")

  data[[variable]] = paste0(data[[variable]], "[", data[["..dimension_values"]], "]")

  data %>%
    select(-..dimension_values) %>%
    spread(!!variable, !!value)
}
