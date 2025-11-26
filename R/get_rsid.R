#' Retrieve rsID from SQLite Database Based on Genomic Coordinates
#'
#' This function queries a SQLite database containing 1000 Genomes Project data
#' to retrieve rsID information based on chromosome, position, and alleles.
#' The function processes queries in batches for optimal performance.
#'
#' @param input_df A data frame containing genomic variant information.
#' @param chr_col Character string specifying the column name for chromosome. Default is "chr".
#' @param pos_col Character string specifying the column name for position. Default is "pos".
#' @param a1_col Character string specifying the column name for allele 1. Default is "A1".
#' @param a2_col Character string specifying the column name for allele 2. Default is "A2".
#' @param db_path Character string specifying the absolute path to the SQLite database.
#'   Default is "/data1/myl4share/SQLite_base/10000genome_2015v3_GRCh37_bimSQLite.db".
#' @param table_name Character string specifying the table name in the database. Default is "snp".
#' @param batch_size Integer specifying the number of variants to process per batch. Default is 100.
#'
#' @return A data.table containing matched SNP information with columns: chr, rsID, pos, A1, A2.
#'
#' @details
#' The function splits the input data into batches to avoid SQL query length limitations.
#' For each variant, it searches for exact matches considering both allele orientations
#' (A1/A2 and A2/A1). Progress messages are printed during execution.
#'
#' @examples
#' \dontrun{
#' # Prepare input data
#' variants <- data.frame(
#'   chr = c("1", "2", "3"),
#'   pos = c(123456, 234567, 345678),
#'   A1 = c("A", "C", "G"),
#'   A2 = c("G", "T", "T")
#' )
#'
#' # Retrieve rsID information
#' results <- get_rsid(
#'   input_df = variants,
#'   chr_col = "chr",
#'   pos_col = "pos",
#'   a1_col = "A1",
#'   a2_col = "A2",
#'   batch_size = 1000
#' )
#' }
#'
#' @importFrom data.table fread setnames rbindlist
#' @export
get_rsid <- function(input_df,
                     chr_col = "chr",
                     pos_col = "pos",
                     a1_col = "A1",
                     a2_col = "A2",
                     db_path = "/data1/myl4share/SQLite_base/10000genome_2015v3_GRCh37_bimSQLite.db",
                     table_name = "snp",
                     batch_size = 100) {
  
  # Check required columns
  required_cols <- c(chr_col, pos_col, a1_col, a2_col)
  if (!all(required_cols %in% names(input_df))) {
    stop("Input data frame must contain the specified columns: ",
         paste(required_cols, collapse = ", "))
  }
  
  # Split into batches
  num_rows <- nrow(input_df)
  partitions <- split(input_df, ceiling(seq_len(num_rows) / batch_size))
  
  all_results <- list()
  
  for (i in seq_along(partitions)) {
    partition <- partitions[[i]]
    cat(sprintf("Processing batch %d of %d...\n", i, length(partitions)))
    
    # Build WHERE conditions
    where_conditions <- apply(partition, 1, function(row) {
      chr <- row[[chr_col]]
      pos <- row[[pos_col]]
      A1 <- row[[a1_col]]
      A2 <- row[[a2_col]]
      sprintf("(chr='%s' AND pos=%s AND ((A1='%s' AND A2='%s') OR (A1='%s' AND A2='%s')))",
              chr, pos, A1, A2, A2, A1)
    })
    
    where_clause <- paste(where_conditions, collapse = " OR ")
    
    # Build complete SQL query
    query <- sprintf("SELECT * FROM %s WHERE %s;", table_name, where_clause)
    
    # Debug output
    cat(sprintf("Executing batch %d SQL Query:\n", i), substr(query, 1, 500), "...", "\n")
    
    # Execute query
    system_cmd <- sprintf("sqlite3 %s \"%s\"", shQuote(db_path), query)
    query_result <- tryCatch(
      system(system_cmd, intern = TRUE),
      error = function(e) {
        message(sprintf("Error executing batch %d: %s", i, e$message))
        return(character(0))
      }
    )
    
    # Parse results
    if (length(query_result) > 0) {
      query_data <- data.table::fread(text = paste(query_result, collapse = "\n"), 
                                       sep = "|", 
                                       header = FALSE)
      col_names <- c("chr", "rsID", "pos", "A1", "A2")
      data.table::setnames(query_data, col_names)
      all_results[[i]] <- query_data
    } else {
      all_results[[i]] <- NULL
    }
  }
  
  # Combine all batch results
  final_results <- data.table::rbindlist(all_results, use.names = TRUE, fill = TRUE)
  
  return(final_results)
}
