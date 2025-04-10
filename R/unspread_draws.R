# unspread_draws
#
# Author: mjskay
###############################################################################

# Names that should be suppressed from global variable check by codetools
# Names used broadly should be put in _global_variables.R
globalVariables(c("..dimension_values"))


#' Turn tidy data frames of variables from a Bayesian model back into untidy data
#'
#' Inverse operations of [spread_draws()] and [gather_draws()], giving
#' results that look like [tidy_draws()].
#'
#' These functions take symbolic specifications of variable names and dimensions in the same format as
#' [spread_draws()] and [gather_draws()] and invert the tidy data frame back into
#' a data frame whose column names are variables with dimensions in them.
#'
#' @param data A tidy data frame of draws, such as one output by `spread_draws` or `gather_draws`.
#' @param ... Expressions in the form of
#' `variable_name[dimension_1, dimension_2, ...]`. See [spread_draws()].
#' @template param-draw_indices
#' @param drop_indices Drop the columns specified by `draw_indices` from the resulting data frame. Default `FALSE`.
#' @param variable The name of the column in `data` that contains the names of variables from the model.
#' @param value The name of the column in `data` that contains draws from the variables.
#' @return A data frame.
#' @author Matthew Kay
#' @seealso [spread_draws()], [gather_draws()], [tidy_draws()].
#' @keywords manip
#' @examples
#'
#' library(dplyr)
#'
#' data(RankCorr, package = "ggdist")
#'
#' # We can use unspread_draws to allow us to manipulate draws with tidybayes
#' # and then transform the draws into a form we can use with packages like bayesplot.
#' # Here we subset b[i,j] to just values of i in 1:2 and j == 1, then plot with bayesplot
#' RankCorr %>%
#'   spread_draws(b[i,j]) %>%
#'   filter(i %in% 1:2, j == 1) %>%
#'   unspread_draws(b[i,j], drop_indices = TRUE) %>%
#'   bayesplot::mcmc_areas()
#'
#' # As another example, we could use compare_levels to plot all pairwise comparisons
#' # of b[1,j] for j in 1:3
#' RankCorr %>%
#'   spread_draws(b[i,j]) %>%
#'   filter(i == 1, j %in% 1:3) %>%
#'   compare_levels(b, by = j) %>%
#'   unspread_draws(b[j], drop_indices = TRUE) %>%
#'   bayesplot::mcmc_areas()
#'
#' @importFrom rlang enquos
#' @importFrom dplyr inner_join ungroup select distinct mutate
#' @importFrom tidyr spread unite
#' @importFrom magrittr %<>% %>%
#' @rdname unspread_draws
#' @export
unspread_draws = function(data, ..., draw_indices = c(".chain", ".iteration", ".draw"), drop_indices = FALSE) {
  draw_indices = intersect(draw_indices, names(data))
  result =
    lapply(enquos(...), function(variable_spec) {
      unspread_draws_(data, variable_spec, draw_indices = draw_indices)
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

unspread_draws_ = function(data, variable_spec, draw_indices = c(".chain", ".iteration", ".draw")) {
  #parse a variable spec in the form variable_name[dimension_name_1, dimension_name_2, ..] | wide_dimension
  spec = parse_variable_spec(variable_spec)
  variable_names = spec[[1]]
  dimension_names = spec[[2]]
  wide_dimension_name = spec[[3]]

  if (!is.null(wide_dimension_name)) {
    stop0("unspread_draws does not support the wide dimension syntax (`|`).")
  }

  # generate the subset of the data that has just the variable names and indices in question
  # we also have to ungroup() here because otherwise grouping columns that are not involved in this variable
  # will be automatically retained even when we try to select() them out.
  data_subset = data %>%
    ungroup() %>%
    select(!!c(draw_indices, variable_names, dimension_names))

  if (is.null(dimension_names)) {
    return(distinct(data_subset))
  }

  # we have to do distinct() here in case a variable had duplicates created for dimensions of
  # other variables that it does not share; e.g. in the case of spread_draws(a, b[i]) %>% unspread_draws(a)
  data_distinct = data_subset %>%
    unite(..dimension_values, !!!dimension_names, sep = ",") %>%
    distinct()

  lapply(variable_names, function(variable_name) {
    data_distinct %>%
      select(!!c(draw_indices, variable_name, "..dimension_values")) %>%
      mutate(..variable = paste0(variable_name, "[", ..dimension_values, "]")) %>%
      select(-..dimension_values) %>%
      spread("..variable", !!variable_name)
  }) %>%
    reduce_(inner_join, by = draw_indices, multiple = "all")
}
