% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_rse.R
\name{calc_confidence}
\alias{calc_confidence}
\title{Calculate confidence score for observing editing}
\usage{
calc_confidence(
  se,
  edit_to = "G",
  edit_from = "A",
  per_sample = FALSE,
  exp_fraction = 0.01,
  alpha = 0L,
  beta = 0L
)
}
\arguments{
\item{se}{\code{SummarizedExperiment::SummarizedExperiment} containing editing
sites}

\item{edit_to}{edited base}

\item{edit_from}{non-edited base}

\item{per_sample}{if TRUE, calculate confidence per sample, otherwise edited
and non-edited counts will be summed across all samples.}

\item{exp_fraction}{Numeric value between 0 and 1, specifying the expected
error rate}

\item{alpha}{Pseudo-count to add to non-edited base counts}

\item{beta}{Pseudo-count to add to edited base counts}
}
\value{
\code{SummarizedExperiment::SummarizedExperiment} with either a new assay
or rowData column named "confidence" depending on whether confidence is
calculated \code{per_sample}.
}
\description{
Calculate a confidence score based on a Bayesian inverse
probability model as described by Washburn et al. Cell Reports. 2015, and
implemented in the SAILOR pipeline.
}
\examples{
rse_adar_ifn <- mock_rse()
calc_confidence(rse_adar_ifn)
calc_confidence(rse_adar_ifn, per_sample = TRUE)

}
\references{
Washburn MC, Kakaradov B, Sundararaman B, Wheeler E, Hoon S, Yeo GW, Hundley
HA. The dsRBP and inactive editor ADR-1 utilizes dsRNA binding to regulate
A-to-I RNA editing across the C. elegans transcriptome. Cell Rep. 2014
Feb 27;6(4):599-607. doi: 10.1016/j.celrep.2014.01.011. Epub 2014 Feb 6.
PMID: 24508457; PMCID: PMC3959997.

SAILOR pipeline: https://github.com/YeoLab/sailor
}
