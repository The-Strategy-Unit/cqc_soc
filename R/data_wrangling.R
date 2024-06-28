# # To get data from a xls file at a URL. Default is to read sheet 1, but can
# # specify other sheet and to not skip any rows.
# scrape_xls <- function(url, sheet = 1, skip = 0) {
#   tmp = tempfile(fileext = "")
#
#   download.file(url = url,
#                 destfile = tmp,
#                 mode = "wb")
#
#   data <- readxl::read_excel(path = tmp,
#                              sheet = sheet,
#                              skip = skip) |>
#     janitor::clean_names()
#
#   return(data)
#
# }
#
# # To get data from the first excel file in a zipped folder at a URL. Default is
# # to read sheet 1 and to not skip any rows.
# scrape_zipped_xls <- function(url, sheet = 1, skip = 0) {
#   download.file(url, "zippeddata.zip")
#   unzip("zippeddata.zip")
#
#   filename <- unzip("zippeddata.zip", list = TRUE) |>
#     dplyr::select(Name) |>
#     dplyr::pull()
#
#   data <- readxl::read_excel(filename,
#                              sheet = sheet,
#                              skip = skip) |>
#     janitor::clean_names()
#
#   unlink("zippeddata.zip", recursive = TRUE)
#   unlink(filename)
#
#   return(data)
#
# }

get_file_from_url_zipped <- function(url){

  download.file(url, "zippeddata.zip")
  unzip("zippeddata.zip")

  filename <- unzip("zippeddata.zip", list = TRUE) |>
    dplyr::select(Name) |>
    dplyr::pull()

  return(filename)

}

tidy_after_unzip <- function(filename){
  unlink("zippeddata.zip", recursive = TRUE)
  unlink(filename)
}

get_pop_by_gender_2018 <- function(url) {

  filename <- get_file_from_url_zipped(url)

  data <- data.frame()

  for(i in c("Persons", "Females", "Males")) {

    data_to_add <- readxl::read_excel(filename,
                                      sheet = glue::glue("Mid-2018 {i}"),
                                      skip = 4) |>
      janitor::clean_names() |>
      dplyr::mutate(type = i) |>
      dplyr::filter(!is.na(lsoa)) |>
      dplyr::select(lsoa_code = area_codes, all_ages, type)

    data <- data |>
      dplyr::bind_rows(data_to_add)
  }

  data <- data |>
    tidyr::pivot_wider(names_from = "type",
                       values_from = all_ages) |>
    dplyr::mutate(year = "2018") |>
    janitor::clean_names()

  tidy_after_unzip(filename)

  return(data)

}

get_pop_by_gender <- function(filename, year){

  data <- data.frame()

  for(i in c("Persons", "Females", "Males")) {
    data_to_add <- readxl::read_excel(filename,
                                      sheet = glue::glue("Mid-{year} {i}"),
                                      skip = 4) |>
      janitor::clean_names() |>
      dplyr::mutate(type = i) |>
      dplyr::select(lsoa_code, all_ages, type)

    data <- data |>
      dplyr::bind_rows(data_to_add)
  }

  data <- data |>
    tidyr::pivot_wider(names_from = "type",
                       values_from = all_ages) |>
    dplyr::mutate(year = year) |>
    janitor::clean_names()

  return(data)
}

get_pop_by_gender_2019 <- function(url, year) {

  filename <- get_file_from_url_zipped(url)

  data <- get_pop_by_gender(filename, year)

  tidy_after_unzip(filename)

  return(data)

}

get_file_from_url <- function(url){
  filename <- tempfile(fileext = "")

  download.file(url = url,
                destfile = filename,
                mode = "wb")

  return(filename)
}

get_pop_by_gender_2020 <- function(url, year) {
  filename <- get_file_from_url(url)

  data <- get_pop_by_gender(filename, year)

  return(data)

}

get_pop_by_gender_2021_22 <- function(url, year){

  filename <- get_file_from_url(url)

  data <- readxl::read_excel(filename,
                             sheet = glue::glue("Mid-{year} LSOA 2021"),
                             skip = 3)  |>
    janitor::clean_names() |>
    dplyr::mutate(females = rowSums(dplyr::across(tidyselect::starts_with("f"))),
                  males = rowSums(dplyr::across(tidyselect::starts_with("m"))),
                  year = year) |>
    dplyr::select(lsoa_code = lsoa_2021_code,
                  "persons" = total,
                  females,
                  males,
                  year)

}





