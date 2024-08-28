# To get data from a xls file at a URL. Default is to read sheet 1 from row 1,
# but can specify other sheet number and number of rows to skip.
scrape_xls <- function(url, sheet = 1, skip = 0) {
  tmp <- tempfile(fileext = "")

  download.file(url = url,
                destfile = tmp,
                mode = "wb")

  data <- readxl::read_excel(path = tmp,
                             sheet = sheet,
                             skip = skip) |>
    janitor::clean_names()

  return(data)

}

# To get data from the first excel file in a zipped folder at a URL. Default is
# to read sheet 1 from row 1, but can specify other sheet number and number of
# rows to skip.
scrape_zipped_xls <- function(url, sheet = 1, skip = 0) {
  download.file(url, "zippeddata.zip")
  unzip("zippeddata.zip")

  filename <- unzip("zippeddata.zip", list = TRUE) |>
    dplyr::select(Name) |>
    dplyr::pull()

  data <- readxl::read_excel(filename, sheet = sheet, skip = skip) |>
    janitor::clean_names()

  unlink("zippeddata.zip", recursive = TRUE)
  unlink(filename)

  return(data)

}

# Add financial year.
add_financial_year <- function(data) {
  data <- data |>
    dplyr::mutate(
      year_plus_one = stringr::str_sub(as.numeric(year) + 1, 3, 4),
      fin_year = glue::glue("{year}/{year_plus_one}")
    )

  return(data)
}

# load specific reference and query files
load_csv <- function(fileloc) {
  data <- read.csv(fileloc) |>
    janitor::clean_names()
}
