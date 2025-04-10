% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compare_levels.R
\name{compare_levels}
\alias{compare_levels}
\title{Compare the value of draws of some variable from a Bayesian model for
different levels of a factor}
\usage{
compare_levels(
  data,
  variable,
  by,
  fun = `-`,
  comparison = "default",
  draw_indices = c(".chain", ".iteration", ".draw"),
  ignore_groups = ".row"
)
}
\arguments{
\item{data}{Long-format \code{data.frame} of draws such as returned by
\code{\link[=spread_draws]{spread_draws()}} or \code{\link[=gather_draws]{gather_draws()}}. If \code{data}
is a grouped data frame, comparisons will be made within groups (if
one of the groups in the data frame is the \code{by} column, that specific
group will be ignored, as it is not possible to make comparisons both
within some variable and across it simultaneously).}

\item{variable}{Bare (unquoted) name of a column in data representing the
variable to compare across levels. Can be a numeric variable (as in
long-data-frame-of-draws format) or a \code{\link[posterior:rvar]{posterior::rvar}}.}

\item{by}{Bare (unquoted) name of a column in data that is a
\code{factor} or \code{ordered}. The value of \code{variable} will be
compared across pairs of levels of this \code{factor}.}

\item{fun}{Binary function to use for comparison. For each pair of levels of
\code{by} we are comparing (as determined by \code{comparison}), compute the
result of this function.}

\item{comparison}{One of (a) the comparison types \code{ordered},
\code{control}, \code{pairwise}, or \code{default} (may also be given as
strings, e.g. \code{"ordered"}), see \emph{Details}; (b) a user-specified
function that takes a \code{factor} and returns a list of pairs of names of
levels to compare (as strings) and/or unevaluated expressions containing
representing the comparisons to make; or (c) a list of pairs of names of
levels to compare (as strings) and/or unevaluated expressions representing
the comparisons to make, e.g.: \code{list(c("a", "b"), c("b", "c"))} or
\code{exprs(a - b, b - c)}, both of which would compare level \code{"a"} against
\code{"b"} and level \code{"b"} against \code{"c"}. Note that the
unevaluated expression syntax ignores the \code{fun} argument, can include
any other functions desired (e.g. variable transformations), and can even
include more than two levels or other columns in \code{data}. Types (b) and
(c) may use named lists, in which case the provided names are used
in the output \code{variable} column instead converting the unevaluated
expression to a string. You can also use \code{\link[=emmeans_comparison]{emmeans_comparison()}} to generate
a comparison function based on contrast methods from the \code{emmeans} package.}

\item{draw_indices}{Character vector of column names that should be treated
as indices of draws. Operations are done within combinations of these values.
The default is \code{c(".chain", ".iteration", ".draw")}, which is the same names
used for chain, iteration, and draw indices returned by \code{\link[=tidy_draws]{tidy_draws()}}.
Names in \code{draw_indices} that are not found in the data are ignored.}

\item{ignore_groups}{character vector of names of groups to ignore by
default in the input grouping. This is primarily provided to make it
easier to pipe output of \code{\link[=add_epred_draws]{add_epred_draws()}} into this function,
as that function provides a \code{".row"} output column that is grouped,
but which is virtually never desired to group by when using \code{compare_levels}.}
}
\value{
A \code{data.frame} with the same columns as \code{data}, except
that the \code{by} column contains a symbolic representation of the
comparison of pairs of levels of \code{by} in \code{data}, and
\code{variable} contains the result of that comparison.
}
\description{
Given posterior draws from a Bayesian model in long format (e.g. as
returned by \code{\link[=spread_draws]{spread_draws()}}), compare the value of a variable in those draws
across different paired combinations of levels of a factor.
}
\details{
This function simplifies conducting comparisons across levels of some
variable in a tidy data frame of draws. It applies \code{fun} to all
values of \code{variable} for each pair of levels of \code{by} as selected
by \code{comparison}. By default, all pairwise comparisons are generated if
\code{by} is an unordered \code{factor} and ordered comparisons are made if
\code{by} is \code{ordered}.

The included \code{comparison} types are: \itemize{ \item \code{ordered}:
compare each level \code{i} with level \code{i - 1}; e.g. \code{fun(i, i - 1)} \item \code{pairwise}: compare each level of \code{by} with every other
level.  \item \code{control}: compare each level of \code{by} with the first
level of \code{by}.  If you wish to compare with a different level, you can
first apply \code{\link[=relevel]{relevel()}} to \code{by} to set the control
(reference) level.  \item \code{default}: use \code{ordered} if
\code{is.ordered(by)} and \code{pairwise} otherwise.  }
}
\examples{

library(dplyr)
library(ggplot2)

data(RankCorr, package = "ggdist")

# Let's do all pairwise comparisons of b[i,1]:
RankCorr \%>\%
  spread_draws(b[i,j]) \%>\%
  filter(j == 1) \%>\%
  compare_levels(b, by = i) \%>\%
  median_qi()

# Or let's plot all comparisons against the first level (control):
RankCorr \%>\%
  spread_draws(b[i,j]) \%>\%
  filter(j == 1) \%>\%
  compare_levels(b, by = i, comparison = control) \%>\%
  ggplot(aes(x = b, y = i)) +
  stat_halfeye()

# Or let's plot comparisons of all levels of j within
# all levels of i
RankCorr \%>\%
  spread_draws(b[i,j]) \%>\%
  group_by(i) \%>\%
  compare_levels(b, by = j) \%>\%
  ggplot(aes(x = b, y = j)) +
  stat_halfeye() +
  facet_grid(cols = vars(i))

}
\seealso{
\code{\link[=emmeans_comparison]{emmeans_comparison()}} to use \code{emmeans}-style contrast methods with
\code{\link[=compare_levels]{compare_levels()}}.
}
\author{
Matthew Kay
}
\keyword{manip}
