% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_rse.R
\name{get_splice_sites}
\alias{get_splice_sites}
\title{Extract regions surrounding splice sites}
\usage{
get_splice_sites(txdb, slop = 4)
}
\arguments{
\item{txdb}{\code{GenomicFeatures::TxDb}}

\item{slop}{The number of bases upstream and downstream of splice site to
extract}
}
\value{
\code{GenomicRanges::GRanges} containing positions of splice sites, with
flanking bases.
}
\description{
Extract intervals at splice sites and their adjacent
regions.
}
\examples{
if (require(TxDb.Hsapiens.UCSC.hg38.knownGene)) {
    txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
    res <- get_splice_sites(txdb)
    res[1:5]
}

}
