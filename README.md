# mygem

**mygem** is an R package focused on genetic and bioinformatics analysis tools.

## Installation

You can install the development version of mygem from GitHub:

```r
# install.packages("devtools")
devtools::install_github("yuanlinm/mygem")
```

## Features

### 1. rsID Retrieval Based on Genomic Coordinates

The `get_rsid()` function retrieves rsID information from a 1000 Genomes Project SQLite database based on chromosome, position, and alleles.

#### Usage Example

```r
library(mygem)

# Prepare input data with genomic variants
variants <- data.frame(
  CHR_bbj = c("1", "2", "3"),
  POS_bbj = c(123456, 234567, 345678),
  EA_bbj = c("A", "C", "G"),
  OA_bbj = c("G", "T", "T")
)

# Retrieve rsID information
results <- get_rsid(
  input_df = variants,
  chr_col = "CHR_bbj",
  pos_col = "POS_bbj",
  a1_col = "EA_bbj",
  a2_col = "OA_bbj",
  batch_size = 1000
)
```

#### Function Parameters

- `input_df`: Data frame containing genomic variant information
- `chr_col`: Column name for chromosome (default: "chr")
- `pos_col`: Column name for position (default: "pos")
- `a1_col`: Column name for allele 1 (default: "A1")
- `a2_col`: Column name for allele 2 (default: "A2")
- `db_path`: Path to SQLite database (default: "/data1/myl4share/SQLite_base/10000genome_2015v3_GRCh37_bimSQLite.db")
- `table_name`: Table name in database (default: "snp")
- `batch_size`: Number of variants per batch (default: 100)

#### Features

- High-speed batch query processing
- Handles both forward and reverse allele orientations
- Progress reporting during execution
- Built on data.table for efficient data handling

## Dependencies

- data.table

## License

MIT
