% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tte_sources.R
\docType{data}
\name{death_event}
\alias{death_event}
\alias{lastalive_censor}
\alias{ae_event}
\alias{ae_ser_event}
\alias{ae_gr1_event}
\alias{ae_gr2_event}
\alias{ae_gr3_event}
\alias{ae_gr4_event}
\alias{ae_gr5_event}
\alias{ae_gr35_event}
\alias{ae_sev_event}
\alias{ae_wd_event}
\title{Pre-Defined Time-to-Event Source Objects}
\usage{
death_event

lastalive_censor

ae_event

ae_ser_event

ae_gr1_event

ae_gr2_event

ae_gr3_event

ae_gr4_event

ae_gr5_event

ae_gr35_event

ae_sev_event

ae_wd_event
}
\description{
These pre-defined \code{tte_source} objects can be used as input to \code{\link[=derive_param_tte]{derive_param_tte()}}.
}
\details{
To see the definition of the various objects simply print the object in the
R console, e.g. \code{print(death_event)}. For details of how to use these objects
please refer to \code{\link[=derive_param_tte]{derive_param_tte()}}.
}
\examples{
# This shows the definition of all pre-defined `tte_source` objects that ship
# with {admiral}
for (obj in list_tte_source_objects()$object) {
  cat(obj, "\n")
  print(get(obj))
  cat("\n")
}
}
\seealso{
\code{\link[=derive_param_tte]{derive_param_tte()}}, \code{\link[=tte_source]{tte_source()}}, \code{\link[=event_source]{event_source()}}, \code{\link[=censor_source]{censor_source()}}

Source Specifications: 
\code{\link{assert_db_requirements}()},
\code{\link{assert_terms}()},
\code{\link{assert_valid_queries}()},
\code{\link{censor_source}()},
\code{\link{date_source}()},
\code{\link{derive_var_dthcaus}()},
\code{\link{event_source}()},
\code{\link{extend_source_datasets}()},
\code{\link{filter_date_sources}()},
\code{\link{format.sdg_select}()},
\code{\link{format.smq_select}()},
\code{\link{list_tte_source_objects}()},
\code{\link{params}()},
\code{\link{query}()},
\code{\link{sdg_select}()},
\code{\link{smq_select}()},
\code{\link{tte_source}()},
\code{\link{validate_query}()},
\code{\link{validate_sdg_select}()},
\code{\link{validate_smq_select}()}
}
\concept{source_specifications}
\keyword{source_specifications}
