#' Calculate the Adenosine Editing Index (AEI)
#'
#' @description The Adenosine Editing Index describes the magnitude of A-to-I editing
#' in a sample. The index is a weighted average of editing events (G bases) observed
#' at A positions. The vast majority A-to-I editing occurs in ALU elements in the human
#' genome, and these regions have a high A-to-I editing signal compared to other regions
#' such as coding exons. This function will perform pileup at specified repeat regions and
#' return a summary AEI metric.
#'
#' @references
#' Roth, S.H., Levanon, E.Y. & Eisenberg, E. Genome-wide quantification of ADAR adenosine-to-inosine RNA editing activity. Nat Methods 16, 1131–1138 (2019). https://doi.org/10.1038/s41592-019-0610-9
#'
#'
#' @param bam_fn bam file
#' @param fasta_fn fasta
#' @param alu_ranges GRanges or the name of a BEDfile with regions to query for calculating the AEI,
#' typically ALU repeats. If a BED file is supplied it will not be filtered by the txdb option.
#' @param txdb A txdb object, if supplied, will be used to subset the alu_ranges to
#' those found overlapping genes.
#' @param snp_db either a SNPlocs package, GPos, or GRanges object. If supplied,
#' will be used to exclude polymorphic positions prior to calculating the AEI. If
#' `calc_AEI()` will be used many times, one could save some time by first identifying
#' SNPs that overlap the supplied alu_ranges, and passing these as a GRanges to snp_db
#' rather than supplying all known SNPs. Combined with using a bedfile for alu_ranges can
#' also will save time.
#' @param library_type library type, one of `fr-first-strand'`, `fr-second-strand`, or `unstranded`
#' @param min_mapq minimum required MAPQ for alignment to be counted
#' @param BPPARAM A [BiocParallelParam] object for specifying parallel options for
#' operating over chromosomes.
#' @param verbose report progress on each chromosome?
#'
#' @returns A named list with the AEI index computed for all allelic combinations.
#' If correctly computed the signal from the A_G index should be higher than other
#' alleles (T_C), which are most likely derived from noise or polymorphisms.
#'
#' @examples
#' suppressPackageStartupMessages(library(Rsamtools))
#' bamfn <- system.file("extdata", "SRR5564277_Aligned.sortedByCoord.out.md.bam", package = "raer")
#' fafn <- system.file("extdata", "human.fasta", package = "raer")
#' dummy_alu_ranges <- scanFaIndex(fafn)
#' calc_AEI(bamfn, fafn, dummy_alu_ranges)
#'
#' @importFrom BiocParallel bpstop bpmapply SerialParam
#' @importFrom GenomicFeatures genes
#' @importFrom rtracklayer export
#' @importFrom Rsamtools scanBamHeader
#' @importFrom IRanges subsetByOverlaps
#' @import S4Vectors
#' @import GenomicRanges
#' @export
calc_AEI <- function(bam_fn,
                     fasta_fn,
                     alu_ranges = NULL,
                     txdb = NULL,
                     snp_db = NULL,
                     min_mapq = 255,
                     library_type = c("fr-first-strand", "fr-second-strand", "unstranded"),
                     BPPARAM = SerialParam(),
                     verbose = FALSE){

  chroms <- names(Rsamtools::scanBamHeader(bam_fn)[[1]]$targets)

  if(length(bam_fn) != 1){
    stop("calc_AEI only operates on 1 bam file at a time")
  }

  if(is.null(alu_ranges)){
    warning("querying the whole genome will be very ",
            "memory intensive and inaccurate.\n",
            "Consider supplying a GRanges object with ALU\n",
            "or related repeats for your species ")
  }

  tmp_files <- NULL
  alu_bed_fn <- NULL
  if(!is.null(alu_ranges)){
    if(is(alu_ranges, "character")){
      if(!file.exists(alu_ranges)){
        stop("supplied alu ranges bedfile does not exist:\n",
             alu_ranges,
             call. = FALSE)
      }
      alu_bed_fn <- alu_ranges

    } else if(is(alu_ranges, "GRanges")){
     alu_bed_fn <- tempfile(fileext = ".bed")
     tmp_files <- c(tmp_files, alu_bed_fn)
     if(!is.null(txdb)){
       gene_gr <- GenomicFeatures::genes(txdb)
       alu_ranges <- subsetByOverlaps(alu_ranges, gene_gr, ignore.strand = TRUE)
       alu_ranges <- reduce(alu_ranges)
     }
     chroms <- intersect(chroms, as.character(unique(seqnames(alu_ranges))))
     alu_ranges <- alu_ranges[seqnames(alu_ranges) %in% chroms]
     rtracklayer::export(alu_ranges, alu_bed_fn)
   } else {
     stop("unrecognized format for alu_ranges")
   }
  }

  snps <- NULL
  if(!is.null(snp_db)){
    if(is(snp_db, "GRanges") || is(snp_db, "GPos")){
      if(is(alu_ranges, "GRanges")){
        snps <- subsetByOverlaps(snp_db, alu_ranges)
        snps <- split(snps, seqnames(snps))[chroms]
      } else {
        chroms <- intersect(chroms, as.character(unique(seqnames(snp_db))))
        snps <- split(snp_db, seqnames(snp_db))[chroms]
      }
    } else if (is(snp_db, "ODLT_SNPlocs")){
      if(is(alu_ranges, "GRanges")){
        snps <- snpsByOverlaps(snp_db, alu_ranges)
        snps <- split(snps, seqnames(snps))[chroms]
      } else {
        stop("removing snps using a SNPloc package requires ",
             "alu_ranges to be supplied ")
      }
    } else {
      stop("unknown snpdb object type")
    }
  }
  if(is.null(snps)){
    aei <- bpmapply(.calc_AEI_per_chrom,
                    chroms,
                    MoreArgs = list(bam_fn = bam_fn,
                                    fasta_fn = fasta_fn,
                                    alu_bed_fn = alu_bed_fn,
                                    min_mapq = min_mapq,
                                    library_type = library_type[1],
                                    snp_gr = NULL,
                                    verbose = verbose),
                    BPPARAM = BPPARAM,
                    SIMPLIFY = FALSE)
  } else {
    if(length(chroms) != length(snps)){
      stop("issue subsetting SNPdb and chromosomes")
    }
    aei <- bpmapply(.calc_AEI_per_chrom,
                    chroms,
                    snps,
                    MoreArgs = list(bam_fn = bam_fn,
                                    fasta_fn = fasta_fn,
                                    alu_bed_fn = alu_bed_fn,
                                    min_mapq = min_mapq,
                                    library_type = library_type[1],
                                    verbose = verbose),
                    BPPARAM = BPPARAM,
                    SIMPLIFY = FALSE)
  }
  bpstop(BPPARAM)

  names(aei) <- chroms
  aei_res <- lapply(seq_along(aei), function(x) {
    vals <- aei[[x]]
    id <- names(aei)[x]
    xx <- as.data.frame(t(do.call(data.frame, vals)))
    xx$allele <- rownames(xx)
    xx$chrom <- id
    rownames(xx) <- NULL
    xx})

  aei_res <- do.call(rbind, aei_res)
  aei_res <- split(aei_res, aei_res$allele)
  aei_res <- lapply(aei_res, function(x) 100 * (sum(x$alt) / (sum(x$ref) + sum(x$alt))))

  if(length(tmp_files) > 0) unlink(tmp_files)
  aei_res
}



.calc_AEI_per_chrom <- function(bam_fn,
                                 fasta_fn,
                                 alu_bed_fn,
                                 chrom,
                                 min_mapq,
                                 library_type,
                                 snp_gr,
                                 verbose) {
  if(verbose){
    start <- Sys.time()
    message("\tworking on: ", chrom, " time: ", Sys.time())
  }
  plp <- get_pileup(bam_fn,
                    fafile = fasta_fn,
                    bedfile = alu_bed_fn,
                    chroms = chrom,
                    min_reads = 1,
                    min_base_qual = 30,
                    min_mapq = min_mapq,
                    library_type = library_type,
                    event_filters = c(5, 5, 0, 0, 0, 0, 0),
                    only_keep_variants = FALSE)
  if(verbose){
    message("\tcompleted in : ", Sys.time() - start)
  }

  if(!is.null(snp_gr) && !is.null(plp)){
    plp <- subsetByOverlaps(plp, snp_gr,
                            invert = TRUE,
                            ignore.strand = TRUE)
  }

  bases <- c("A", "T", "C", "G")
  var_list <- list()
  for(i in seq_along(bases)){
    rb <- bases[i]
    other_b <- setdiff(bases, rb)
    j <- plp[plp$Ref == rb]
    for(k in seq_along(other_b)){
      ab <- other_b[k]
      id <- paste0(rb, "_", ab)
      n_alt <- sum(mcols(j)[[paste0("n", ab)]])
      n_ref <- sum(mcols(j)[[paste0("n", rb)]])
      var_list[[id]]  <- c(alt = n_alt,
                           ref = n_ref,
                           prop = 0)
    }
  }
  var_list
}