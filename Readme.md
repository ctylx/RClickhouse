# RClickhouse

![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg) ![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](https://img.shields.io/github/release/IMSMWU/RClickhouse.svg) [![Build Status](https://travis-ci.org/IMSMWU/RClickhouse.svg?branch=master)](https://travis-ci.org/IMSMWU/RClickhouse)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/RClickhouse)](https://cran.r-project.org/package=RClickhouse)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/RClickhouse)](https://cran.r-project.org/package=RClickhouse)

## Overview

[ClickHouse &copy;](https://clickhouse.com/) is a high-performance relational column-store database to enable big data exploration and 'analytics' scaling to petabytes of data. Methods are provided that enable working with 'Yandex Clickhouse' databases via 'DBI' methods and using 'dplyr'/'dbplyr' idioms.

This R package is a DBI interface for the Yandex Clickhouse database. It provides basic dplyr support by auto-generating SQL-commands using dbplyr and is based on the official [C++ Clickhouse Client](https://github.com/ClickHouse/clickhouse-cpp).

This package includes vendored copies of [clickhouse-cpp](https://github.com/ClickHouse/clickhouse-cpp) (Apache 2.0) and [Abseil](https://github.com/abseil/abseil-cpp) (Apache 2.0) libraries. See LICENSE file for details.

To cite this library, please use the BibTeX entry provided in **inst/CITATION**.


## Installation
This package is available on CRAN, and thus installable by running:

```R
install.packages("RClickhouse")
```

You can also install the latest development version directly from github using devtools:

```R
devtools::install_github("IMSMWU/RClickhouse")
```

## Usage

#### Create a DBI Connection:

> *Note:* please be aware that {RClickhouse} doesn't use a HTTP interface in order to communicate with Clickhouse. Thus, You may use the native interface port (by default 9000) instead of the HTTP interface (8123).


``` r
con <- DBI::dbConnect(RClickhouse::clickhouse(), host="example-db.com")
```

#### Write data to the database:

``` r
DBI::dbWriteTable(con, "mtcars", mtcars)

dbListTables(con)
dbListFields(con, "mtcars") 
```

#### Query a database using [dplyr](https://dplyr.tidyverse.org/):

``` r
library(dplyr)
tbl(con, "mtcars") %>% 
  group_by(cyl) %>% 
  summarise(smpg=sum(mpg))
  
tbl(con, "mtcars") %>% 
  filter(cyl == 8, vs == 0) %>% 
  group_by(am) %>% 
  summarise(mean(qsec))

# Close the connection
dbDisconnect(con)
```

#### Query a database using [SQL-style commands](https://www.codecademy.com/articles/sql-commands) with `DBI::dbGetQuery`:

``` r
DBI::dbGetQuery(con, "SELECT
                             vs
                            ,COUNT(*) AS 'number of cases'
                            ,AVG(qsec) AS 'average qsec'
                      FROM mtcars
                      GROUP BY vs")

# Save results of querying:
res <- DBI::dbGetQuery(con, "SELECT (*)
                             FROM mtcars
                             WHERE am = 1")

# Or save the whole set of data (only useful for smaller datasets, for better performance and for larger datasets always use remote servers):
mtcars <- dbReadTable(con, mtcars)

# Close the connection
dbDisconnect(con)
```

#### Query a database using [ClickHouse functions](https://clickhouse.yandex/docs/en/query_language/functions/)

``` r
# Get the names of all the avaliable databases
DBI::dbGetQuery(con, "SHOW DATABASES")

# Get information about the variable names and types
DBI::dbGetQuery(con, "DESCRIBE TABLE mtcars")

# Compact CASE - WHEN - THEN conditionals
DBI::dbGetQuery(con, "SELECT multiIf(am='1', 'automatic', 'manual') AS 'transmission'
                            ,multiIf(vs='1', 'straight', 'V-shaped') AS 'engine' 
                      FROM mtcars")

# Close the connection
dbDisconnect(con)
```

#### DateTime64 Support

RClickhouse supports ClickHouse's `DateTime64` type. Due to R's `POSIXct` limitation, sub-second precision is truncated to whole seconds.

**Query DateTime64:**
``` r
# Query DateTime64 values (precision > 0 is truncated to seconds in R)
DBI::dbGetQuery(con, "SELECT toDateTime64(now(), 3) as dt64")
```

**Insert DateTime64:**
``` r
# Insert DateTime64 via POSIXct (sub-second precision truncated)
df <- data.frame(ts = as.POSIXct(Sys.time()))
DBI::dbWriteTable(con, "datetime_table", df)
```

**Precision behavior:** When inserting with precision > 0 (e.g., milliseconds, microseconds), the fractional seconds are truncated to whole seconds due to R's `POSIXct` representation.

For more details on DateTime64, see [ClickHouse DateTime64 documentation](https://clickhouse.com/docs/en/sql-reference/data-types/datetime64/).

### Config File
You may use a config file that is looked up for automatic initialization of the dbConnect parameters.

To do so, create a yaml file (default ```RClickhouse.yaml```), in at least one directory (default lookup paths of parameter config_paths: ```./RClickhouse.yaml, ~/.R/RClickhouse.yaml, /etc/RClickhouse.yaml```), e.g. ```~/.R/configs/RClickhouse.yaml``` and pass a vector of the corresponding file paths to ```dbConnect``` as ```config_paths``` parameter.
In ```RClickhouse.yaml```, you may specify a variable number of parameters (```host, port, db, user, password, compression```) to be initialized using the following format (example):
```YAML
host: example-db.com
port: 1111
```
The actual initialization of the parameters of ```dbConnect``` follows a hierarchical structure with varying priorities (1 to 3, where 1 is highest):
 1. Specified input parameters when calling ```dbConnect```. If parameters are unspecified, fall back to (2)
 2. Parameters specified in ```RClickhouse.yaml```, where the level of priority depends on the position of the path in the config_path input vector (first position, highest priority etc.). If parameters are unspecified, fall back to (3).
 3. Default parameters (```host="localhost", port = 9000, db = "default", user = "default", password = "", compression = "lz4"```).


## Acknowledgements
Big thanks to Kirill Müller, Maxwell Peterson, Artemkin Pavel and Hannes Mühleisen.
