% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pileup.R
\name{pileup_sites}
\alias{pileup_sites}
\alias{FilterParam}
\title{Generate base counts using pileup}
\usage{
pileup_sites(
  bamfiles,
  fasta,
  sites = NULL,
  region = NULL,
  chroms = NULL,
  param = FilterParam(),
  BPPARAM = SerialParam(),
  umi_tag = NULL,
  verbose = FALSE
)

FilterParam(
  max_depth = 10000,
  min_depth = 1L,
  min_base_quality = 20L,
  min_mapq = 0L,
  library_type = "fr-first-strand",
  bam_flags = NULL,
  only_keep_variants = FALSE,
  trim_5p = 0L,
  trim_3p = 0L,
  ftrim_5p = 0,
  ftrim_3p = 0,
  indel_dist = 0L,
  splice_dist = 0L,
  min_splice_overhang = 0L,
  homopolymer_len = 0L,
  max_mismatch_type = c(0L, 0L),
  read_bqual = c(0, 0),
  min_variant_reads = 0L,
  min_allelic_freq = 0,
  report_multiallelic = TRUE,
  remove_overlaps = TRUE
)
}
\arguments{
\item{bamfiles}{a character vector, \link{BamFile} or \link{BamFileList} indicating 1
or more BAM files to process. If named, the names will be included in the
\link{colData} of the \link{RangedSummarizedExperiment} as a \code{sample} column, otherwise
the names will be taken from the basename of the BAM file.}

\item{fasta}{path to genome fasta file used for read alignment. Can be
provided in compressed gzip or bgzip format.}

\item{sites}{a \link{GRanges} object containing regions or sites to process.}

\item{region}{samtools region query string (i.e. \code{chr1:100-1000}). Can be
combined with sites, in which case sites will be filtered to keep only sites
within the region.}

\item{chroms}{chromosomes to process, provided as a character vector. Not to
be used with the region parameter.}

\item{param}{object of class \code{\link[=FilterParam]{FilterParam()}} which specify various
filters to apply to reads and sites during pileup.}

\item{BPPARAM}{A \link{BiocParallel} class to control parallel execution. Parallel
processing occurs per chromosome and is disabled when run on a single
region.}

\item{umi_tag}{The BAM tag containing a UMI sequence. If supplied, multiple
reads with the same UMI sequence will only be counted once per position.}

\item{verbose}{if TRUE, then report progress and warnings.}

\item{max_depth}{maximum read depth considered at each site}

\item{min_depth}{min read depth needed to report site}

\item{min_base_quality}{min base quality score to consider read for pileup}

\item{min_mapq}{minimum required MAPQ score. Values for each input BAM file
can be provided as a vector.}

\item{library_type}{read orientation, one of \code{fr-first-strand},
\code{fr-second-strand}, and \code{unstranded}. Unstranded library
type will be reported with variants w.r.t the + strand. Values for each
input BAM file can be provided as a vector.}

\item{bam_flags}{bam flags to filter or keep, use \code{\link[Rsamtools:ScanBamParam-class]{Rsamtools::scanBamFlag()}}
to generate.}

\item{only_keep_variants}{if TRUE, then only variant sites will be reported
(FALSE by default). Values for each input BAM file can be provided as a
vector.}

\item{trim_5p}{Bases to trim from 5' end of read alignments}

\item{trim_3p}{Bases to trim from 3' end of read alignments}

\item{ftrim_5p}{Fraction of bases to trim from 5' end of read alignments}

\item{ftrim_3p}{Fraction of bases to trim from 3' end of read alignments}

\item{indel_dist}{Exclude read if site occurs within given
distance from indel event in the read}

\item{splice_dist}{Exclude read if site occurs within given
distance from splicing event in the read}

\item{min_splice_overhang}{Exclude read if site is located adjacent to splice
site with an overhang less than given length.}

\item{homopolymer_len}{Exclude site if occurs within homopolymer of given
length}

\item{max_mismatch_type}{Exclude read if it has X different mismatch types
(e.g A-to-G, G-to-C, C-to-G, is 3 mismatch types) or Y # of mismatches,
must be supplied as a integer vector of length 2. e.g.
c(X, Y).}

\item{read_bqual}{Exclude read if more than X percent of the bases have
base qualities less than Y. Numeric vector of length 2. e.g. c(0.25, 20)}

\item{min_variant_reads}{Required number of reads containing a variant for a
site to be reported. Calculated per bam file, such that if 1 bam file has >=
min_variant_reads, then the site will be reported.}

\item{min_allelic_freq}{minimum allelic frequency required for a variant to
be reported in ALT assay.}

\item{report_multiallelic}{if TRUE, report sites with multiple variants
passing filters. If FALSE, site will not be reported.}

\item{remove_overlaps}{if TRUE, enable read pair overlap detection, which
will count only 1 read in regions where read pairs overlap using the htslib
algorithm. In brief for each overlapping base pair the base quality of the
base with the lower quality is set to 0, which discards it from being
counted.}
}
\value{
A \link{RangedSummarizedExperiment} object populated with
multiple assays:
\itemize{
\item \code{ALT}:  Alternate base(s) found at each position
\item \code{nRef}: # of reads supporting the reference base
\item \code{nAlt}: # of reads supporting an alternate base
\item \code{nA}: # of reads with A
\item \code{nT}: # of reads with T
\item \code{nC}: # of reads with C
\item \code{nG}: # of reads with G
}

The \code{\link[=rowRanges]{rowRanges()}} contains the genomic interval for each site, along with:
\itemize{
\item \code{REF}: The reference base
\item \code{rpbz}: Mann-Whitney U test of Read Position Bias from bcftools,
extreme negative or positive values indicate more bias.
\item \code{vdb}: Variant Distance Bias for filtering splice-site artifacts from
bcftools, lower values indicate more bias.
\item \code{sor} Strand Odds Ratio Score, strand bias estimated by the Symmetric
Odds Ratio test, based on GATK code. Higher values indicate more bias.
}

The rownames will be populated with the format
\verb{site_[seqnames]_[position(1-based)]_[strand]}, with \code{strand} being encoded
as 1 = +, 2 = -, and 3 = *.
}
\description{
This function uses a pileup routine to examine numerate base
counts from alignments at specified sites, regions, or across all read
alignments, from one or more BAM files. Alignment and site filtering
options are controlled by the \code{FilterParam} class. A
\link{RangedSummarizedExperiment} object is returned, populated with base count
statistics for each supplied BAM file.
}
\examples{
library(SummarizedExperiment)
bamfn <- raer_example("SRR5564269_Aligned.sortedByCoord.out.md.bam")
bam2fn <- raer_example("SRR5564277_Aligned.sortedByCoord.out.md.bam")
fafn <- raer_example("human.fasta")

rse <- pileup_sites(bamfn, fafn)

fp <- FilterParam(only_keep_variants = TRUE, min_depth = 55)
pileup_sites(bamfn, fafn, param = fp)


# using multiple bam files

bams <- rep(c(bamfn, bam2fn), each = 3)
sample_ids <- paste0(rep(c("KO", "WT"), each = 3), 1:3)
names(bams) <- sample_ids

fp <- FilterParam(only_keep_variants = TRUE)
rse <- pileup_sites(bams, fafn, param = fp)
rse

rse$condition <- substr(rse$sample, 1, 2)
assays(rse)

colData(rse)

rowRanges(rse)

# specifying regions to query using GRanges object

sites <- rowRanges(rse)
rse <- pileup_sites(bams, fafn, sites = sites)
rse

rse <- pileup_sites(bams, fafn, chroms = c("SPCS3", "DHFR"))
rse

rse <- pileup_sites(bams, fafn, region = "DHFR:100-101")
rse

}
\seealso{
Other pileup: 
\code{\link{pileup_cells}()}
}
\concept{pileup}
