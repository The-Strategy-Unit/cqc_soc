

# create 2011 ethnicities by ICB ----
create2011ethnicities <- function(){

# import ethnicity by 2011 lsoa data
ethn_2011_by_lsoa.data <- read.csv("data/ethnicity_by_LSOA11_data.csv") |>
  filter(grepl("E01", GeographyCode))

# import the headings for the ethnicity by 2011 lsoa data
# only keeping the vars i want from it as a lookup
ethn_2011_by_lsoa.heads <- read.csv("data/ethnicity_by_LSOA11_headings.csv")[, c(1,4)]

# next task is to rename the column headers in the ethnicity by 2011 lsoa data
# note that it only has names for the actual ethnicities, ignoring the LSOA name, so I'm adding that in manually to the list so that I can crudely link the two by order - I have manually checked that this works, but it is obviously janky
colnames(ethn_2011_by_lsoa.data) = c("LSOA11CD", ethn_2011_by_lsoa.heads$ColumnVariableDescription)
# this should be improved, so that this happens via lookup rather than just relying on the order of the variables (see https://stackoverflow.com/questions/43742369/rename-variables-via-lookup-table-in-r/43742442#43742442)

# drop some columns from the ethnicity by lsoa data so that everything is more manageable
ethn_2011_by_lsoa.data2 <- ethn_2011_by_lsoa.data %>%
  transmute(LSOA11CD = LSOA11CD,
            All_Ethnicities = `All categories: Age, All categories: Ethnic group`,
            White = `All categories: Age, White: Total`,
            Mixed = `All categories: Age, Mixed/multiple ethnic group: Total`,
            Asian = `All categories: Age, Asian/Asian British: Total`,
            Black = `All categories: Age, Black/African/Caribbean/Black British: Total`,
            Other = `All categories: Age, Other ethnic group: Total`)

# import 2011 to ICB data lookup
lsoa11_to_ICB23 <- read.csv("data/LSOA2011_to_ICB2023.csv") %>%
  clean_names()

# join lsoa to icb lookup
ethnicity_by_lsoa_by_icb <- inner_join(x = ethn_2011_by_lsoa.data2, y = lsoa11_to_ICB23,
                                      by = c("LSOA11CD" = "lsoa11cd"))
# n of rows of lsoas is 32844, which is correct for n of lsoas in england during 2011

ethnicity2011_by_icb2023 <- ethnicity_by_lsoa_by_icb %>%
  # pivot longer for ease of wrangling
  pivot_longer(cols = c(3:7),
               names_to = "Ethnicity",
               values_to = "Count11") %>%
  # create aggregate count of each ethnic group
  group_by(icb23cd, icb23nm, Ethnicity) %>%
  summarise(Count11 = sum(Count11),
            All_Ethnicities11 = sum(All_Ethnicities)) |>
  ungroup() %>%
  select(Ethnicity, Count11, All_Ethnicities11, icb23cd)

return(ethnicity2011_by_icb2023)

}


# create 2021 ethnicities by ICB ----
create2021ethnicities <- function(){
# import ethnicity by lsoa,  this includes welsh lsoa
ethn_2021_by_lsoa <- read_csv("data/ethnicity_by_LSOA21.csv",
                              show_col_types = FALSE) %>%
  transmute(LSOA21CD = `geography code`,
            All_Ethnicities = `Ethnic group: Total: All usual residents`,
            White = `Ethnic group: White`,
            Mixed = `Ethnic group: Mixed or Multiple ethnic groups`,
            Asian = `Ethnic group: Asian, Asian British or Asian Welsh`,
            Black = `Ethnic group: Black, Black British, Black Welsh, Caribbean or African`,
            Other = `Ethnic group: Other ethnic group`)

# import 21 lsoa to icb lookup, only english lsoas
LSOA2021_to_ICB <- read_csv("data/LSOA2021_to_ICB2023.csv",
                            show_col_types = FALSE) %>%
  clean_names()

# join and aggregate
ethnicity2021_by_icb2023 <- left_join(x = LSOA2021_to_ICB, y = ethn_2021_by_lsoa,
                                        by = c("lsoa21cd" = "LSOA21CD")) %>%
  pivot_longer(cols = c(White, Mixed, Asian, Black, Other),
               names_to = "Ethnicity",
               values_to = "Count") %>%
  group_by(icb23cd, icb23nm, Ethnicity) %>%
  summarise(Count21 = sum(Count),
            All_Ethnicities21 = sum(All_Ethnicities,
                                  Year = 2021)) %>%
  ungroup() %>%
  select(Ethnicity, Count21, All_Ethnicities21, icb23cd, icb23nm)

return(ethnicity2021_by_icb2023)
}

# join datasets ----
join_ethnicity <- function(ethnicity2011_by_icb2023 = ethnicity2011_by_icb2023,
                           ethnicity2021_by_icb2023 = ethnicity2021_by_icb2023){

ethnicity_by_icb <- full_join(x = ethnicity2011_by_icb2023, y = ethnicity2021_by_icb2023)

return(ethnicity_by_icb)

}

# impute ethnicity ----
impute_annual_ethnicity <- function(ethnicity_by_icb = ethnicity_by_icb){
# impute annual data
ethnicity_by_icb2 <- ethnicity_by_icb %>%
  mutate(yearly_diff = (Count21 - Count11)/10,
         Count12 = Count11 + (yearly_diff * 1),
         Count13 = Count11 + (yearly_diff * 2),
         Count14 = Count11 + (yearly_diff * 3),
         Count15 = Count11 + (yearly_diff * 4),
         Count16 = Count11 + (yearly_diff * 5),
         Count17 = Count11 + (yearly_diff * 6),
         Count18 = Count11 + (yearly_diff * 7),
         Count19 = Count11 + (yearly_diff * 8),
         Count20 = Count11 + (yearly_diff * 9),
         Count22 = Count11 + (yearly_diff * 11),
         Count23 = Count11 + (yearly_diff * 12)) %>%
  select(-c(yearly_diff, All_Ethnicities11, All_Ethnicities21)) %>%
  pivot_longer(cols = c(Count11, Count12, Count13, Count14, Count15,
                        Count16, Count17, Count18, Count19, Count20,
                        Count21, Count22, Count23),
               names_to = "Year",
               values_to = "Count") %>%
  mutate(Year = stringr::str_replace(string = Year,
                                      pattern = "Count",
                                      replacement = ""))

# impute annual data
ethnicity_by_icb3 <- ethnicity_by_icb %>%
  mutate(yearly_diff = (All_Ethnicities21 - All_Ethnicities11)/10,
         All_Ethnicities12 = All_Ethnicities11 + (yearly_diff * 1),
         All_Ethnicities13 = All_Ethnicities11 + (yearly_diff * 2),
         All_Ethnicities14 = All_Ethnicities11 + (yearly_diff * 3),
         All_Ethnicities15 = All_Ethnicities11 + (yearly_diff * 4),
         All_Ethnicities16 = All_Ethnicities11 + (yearly_diff * 5),
         All_Ethnicities17 = All_Ethnicities11 + (yearly_diff * 6),
         All_Ethnicities18 = All_Ethnicities11 + (yearly_diff * 7),
         All_Ethnicities19 = All_Ethnicities11 + (yearly_diff * 8),
         All_Ethnicities20 = All_Ethnicities11 + (yearly_diff * 9),
         All_Ethnicities22 = All_Ethnicities11 + (yearly_diff * 11),
         All_Ethnicities23 = All_Ethnicities11 + (yearly_diff * 12)) %>%
  select(-c(yearly_diff, Count11, Count21)) %>%
  pivot_longer(cols = c(All_Ethnicities11, All_Ethnicities12, All_Ethnicities13, All_Ethnicities14, All_Ethnicities15,
                        All_Ethnicities16, All_Ethnicities17, All_Ethnicities18, All_Ethnicities19, All_Ethnicities20,
                        All_Ethnicities21, All_Ethnicities22, All_Ethnicities23),
               names_to = "Year",
               values_to = "All_Ethnicities") %>%
  mutate(Year = stringr::str_replace(string = Year,
                                     pattern = "All_Ethnicities",
                                     replacement = ""))

ethnicity_by_icb4 <- full_join(ethnicity_by_icb2,  ethnicity_by_icb3) %>%
  mutate(Percentage_Of_ICB = Count/All_Ethnicities,
         Year = as.numeric(Year) + 2000,
         der_financial_year = case_when(Year == 2011 ~ as.factor("2011/12"),
                                        Year == 2012 ~ as.factor("2012/13"),
                                        Year == 2013 ~ as.factor("2013/14"),
                                        Year == 2014 ~ as.factor("2014/15"),
                                        Year == 2015 ~ as.factor("2015/16"),
                                        Year == 2016 ~ as.factor("2016/17"),
                                        Year == 2017 ~ as.factor("2017/18"),
                                        Year == 2018 ~ as.factor("2018/19"),
                                        Year == 2019 ~ as.factor("2019/20"),
                                        Year == 2020 ~ as.factor("2020/21"),
                                        Year == 2021 ~ as.factor("2021/22"),
                                        Year == 2022 ~ as.factor("2022/23"),
                                        Year == 2023 ~ as.factor("2023/24"),
                                        TRUE ~ as.factor(Year)))

return(ethnicity_by_icb4)

}


