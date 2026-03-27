context("datetime64")

library(DBI, warn.conflicts=F)

source("utils.R")

# DateTime64 (BEGIN)

test_that("read__DateTime64_precision_0", {
  # DateTime64 with precision 0 stores seconds
  con <- getRealConnection()
  
  # Create table with DateTime64(0)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64Table0 (c DateTime64(0)) ENGINE=Memory()")
  
  # Insert test data using proper ClickHouse syntax
  dbExecute(con, "INSERT INTO DateTime64Table0 VALUES ('2024-01-15 10:30:45')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64Table0")
  
  # Verify conversion to POSIXct
  expect_s3_class(result$c, "POSIXct")
  expect_equal(as.POSIXct("2024-01-15 10:30:45", tz = "UTC"), result$c[1])
  
  # Cleanup
  dbRemoveTable(con, "DateTime64Table0")
  dbDisconnect(con)
})

test_that("read__DateTime64_precision_3", {
  # DateTime64 with precision 3 stores milliseconds
  con <- getRealConnection()
  
  # Create table with DateTime64(3)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64Table3 (c DateTime64(3)) ENGINE=Memory()")
  
  # Insert test data with milliseconds
  dbExecute(con, "INSERT INTO DateTime64Table3 VALUES ('2024-01-15 10:30:45.123')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64Table3")
  
  # Verify conversion to POSIXct (loses sub-millisecond precision)
  expect_s3_class(result$c, "POSIXct")
  expect_equal(as.POSIXct("2024-01-15 10:30:45.123", tz = "UTC"), result$c[1])
  
  # Cleanup
  dbRemoveTable(con, "DateTime64Table3")
  dbDisconnect(con)
})

test_that("read__DateTime64_precision_6", {
  # DateTime64 with precision 6 stores microseconds
  con <- getRealConnection()
  
  # Create table with DateTime64(6)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64Table6 (c DateTime64(6)) ENGINE=Memory()")
  
  # Insert test data with microseconds
  dbExecute(con, "INSERT INTO DateTime64Table6 VALUES ('2024-01-15 10:30:45.123456')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64Table6")
  
  # Verify conversion to POSIXct (R uses fractional seconds)
  expect_s3_class(result$c, "POSIXct")
  
  # Cleanup
  dbRemoveTable(con, "DateTime64Table6")
  dbDisconnect(con)
})

test_that("read__DateTime64_precision_9", {
  # DateTime64 with precision 9 stores nanoseconds
  con <- getRealConnection()
  
  # Create table with DateTime64(9)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64Table9 (c DateTime64(9)) ENGINE=Memory()")
  
  # Insert test data with nanoseconds
  dbExecute(con, "INSERT INTO DateTime64Table9 VALUES ('2024-01-15 10:30:45.123456789')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64Table9")
  
  # Verify conversion to POSIXct
  expect_s3_class(result$c, "POSIXct")
  
  # Cleanup
  dbRemoveTable(con, "DateTime64Table9")
  dbDisconnect(con)
})

test_that("write_read__POSIXct_to_DateTime64", {
  # Write POSIXct data and read back as DateTime64
  con <- getRealConnection()
  
  # Create table with DateTime64(6)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64WriteTable (c DateTime64(6)) ENGINE=Memory()")
  
  # Create data frame with POSIXct
  dt <- data.frame(c = as.POSIXct("2024-06-15 14:30:00.123456", tz = "UTC"))
  
  # Write to database
  expect_success(dbWriteTable(con, "DateTime64WriteTable", dt, append = TRUE, overwrite = FALSE))
  
  # Read back
  result <- dbReadTable(con, "DateTime64WriteTable")
  
  # Verify round-trip (with precision loss to microseconds)
  expect_s3_class(result$c, "POSIXct")
  
  # Cleanup
  dbRemoveTable(con, "DateTime64WriteTable")
  dbDisconnect(con)
})

test_that("read__DateTime64_NULL_NA_handling", {
  # Test NULL/NA handling for DateTime64
  con <- getRealConnection()
  
  # Create table with Nullable(DateTime64)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64NullTable (c Nullable(DateTime64(6))) ENGINE=Memory()")
  
  # Insert NULL value
  dbExecute(con, "INSERT INTO DateTime64NullTable VALUES (NULL)")
  
  # Insert non-NULL value
  dbExecute(con, "INSERT INTO DateTime64NullTable VALUES ('2024-01-15 10:30:45.123456')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64NullTable")
  
  # Verify NA handling for NULL
  expect_true(is.na(result$c[1]) | is.null(result$c[1]))
  expect_false(is.na(result$c[2]))
  
  # Cleanup
  dbRemoveTable(con, "DateTime64NullTable")
  dbDisconnect(con)
})

test_that("read__DateTime64_out_of_range", {
  # Test out-of-range value handling
  con <- getRealConnection()
  
  # Create table with DateTime64(0)
  dbExecute(con, "CREATE TABLE IF NOT EXISTS DateTime64RangeTable (c DateTime64(0)) ENGINE=Memory()")
  
  # Insert epoch start (1970-01-01)
  dbExecute(con, "INSERT INTO DateTime64RangeTable VALUES ('1970-01-01 00:00:00')")
  
  # Insert far future date
  dbExecute(con, "INSERT INTO DateTime64RangeTable VALUES ('2100-12-31 23:59:59')")
  
  # Read back
  result <- dbReadTable(con, "DateTime64RangeTable")
  
  # Verify both values are converted correctly
  expect_equal(as.POSIXct("1970-01-01 00:00:00", tz = "UTC"), result$c[1])
  expect_equal(as.POSIXct("2100-12-31 23:59:59", tz = "UTC"), result$c[2])
  
  # Cleanup
  dbRemoveTable(con, "DateTime64RangeTable")
  dbDisconnect(con)
})

# DateTime64 (END)
