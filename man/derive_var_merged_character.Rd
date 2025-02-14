% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/derive_merged.R
\name{derive_var_merged_character}
\alias{derive_var_merged_character}
\title{Merge a Character Variable}
\usage{
derive_var_merged_character(
  dataset,
  dataset_add,
  by_vars,
  order = NULL,
  new_var,
  source_var,
  case = NULL,
  filter_add = NULL,
  mode = NULL,
  missing_value = NA_character_
)
}
\arguments{
\item{dataset}{Input dataset

The variables specified by the \code{by_vars} parameter are expected.}

\item{dataset_add}{Additional dataset

The variables specified by the \code{by_vars}, the \code{source_var}, and the \code{order}
parameter are expected.}

\item{by_vars}{Grouping variables

The input dataset and the selected observations from the additional dataset
are merged by the specified by variables. The by variables must be a unique
key of the selected observations.

\emph{Permitted Values}: list of variables created by \code{vars()}}

\item{order}{Sort order

If the parameter is set to a non-null value, for each by group the first or
last observation from the additional dataset is selected with respect to the
specified order.

\emph{Default}: \code{NULL}

\emph{Permitted Values}: list of variables or \verb{desc(<variable>)} function calls
created by \code{vars()}, e.g., \code{vars(ADT, desc(AVAL))} or \code{NULL}}

\item{new_var}{New variable

The specified variable is added to the additional dataset and set to the
transformed value with respect to the \code{case} parameter.}

\item{source_var}{Source variable}

\item{case}{Change case

Changes the case of the values of the new variable.

\emph{Default}: \code{NULL}

\emph{Permitted Values}: \code{NULL}, \code{"lower"}, \code{"upper"}, \code{"title"}}

\item{filter_add}{Filter for additional dataset (\code{dataset_add})

Only observations fulfilling the specified condition are taken into account
for merging. If the parameter is not specified, all observations are
considered.

\emph{Default}: \code{NULL}

\emph{Permitted Values}: a condition}

\item{mode}{Selection mode

Determines if the first or last observation is selected. If the \code{order}
parameter is specified, \code{mode} must be non-null.

If the \code{order} parameter is not specified, the \code{mode} parameter is ignored.

\emph{Default}: \code{NULL}

\emph{Permitted Values}: \code{"first"}, \code{"last"}, \code{NULL}}

\item{missing_value}{Values used for missing information

The new variable is set to the specified value for all by groups without
observations in the additional dataset.

\emph{Default}: \code{NA_character_}

\emph{Permitted Value}: A character scalar}
}
\value{
The output dataset contains all observations and variables of the
input dataset and additionally the variable specified for \code{new_var} derived
from the additional dataset (\code{dataset_add}).
}
\description{
Merge a character variable from a dataset to the input dataset. The
observations to merge can be selected by a condition and/or selecting the
first or last observation for each by group.
}
\details{
\enumerate{
\item The additional dataset is restricted to the observations matching the
\code{filter_add} condition.
\item The (transformed) character variable is added to the additional dataset.
\item If \code{order} is specified, for each by group the first or last observation
(depending on \code{mode}) is selected.
\item The character variable is merged to the input dataset.
}
}
\examples{
library(admiral.test)
library(dplyr, warn.conflicts = FALSE)
data("admiral_dm")
data("admiral_ds")

derive_var_merged_character(
  admiral_dm,
  dataset_add = admiral_ds,
  by_vars = vars(STUDYID, USUBJID),
  new_var = DISPSTAT,
  filter_add = DSCAT == "DISPOSITION EVENT",
  source_var = DSDECOD,
  case = "title"
) \%>\%
  select(STUDYID, USUBJID, AGE, AGEU, DISPSTAT)
}
\seealso{
General Derivation Functions for all ADaMs that returns variable appended to dataset:
\code{\link{derive_var_confirmation_flag}()},
\code{\link{derive_var_extreme_flag}()},
\code{\link{derive_var_last_dose_amt}()},
\code{\link{derive_var_last_dose_date}()},
\code{\link{derive_var_last_dose_grp}()},
\code{\link{derive_var_merged_cat}()},
\code{\link{derive_var_merged_exist_flag}()},
\code{\link{derive_var_obs_number}()},
\code{\link{derive_var_worst_flag}()},
\code{\link{derive_vars_last_dose}()},
\code{\link{derive_vars_merged_lookup}()},
\code{\link{derive_vars_merged}()},
\code{\link{derive_vars_transposed}()},
\code{\link{get_summary_records}()}
}
\author{
Stefan Bundfuss
}
\concept{der_gen}
\keyword{der_gen}
