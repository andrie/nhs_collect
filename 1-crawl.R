library(Rcrawler)
library(magrittr)
library(dplyr)

url <- "https://digital.nhs.uk/data-and-information/publications/statistical/practice-level-prescribing-data"

filter <- ".*practice-level-prescribing-data.*"

Rcrawler(
  Website = url, no_cores = 2, no_conn = 2, 
  MaxDepth = 1, Obeyrobots = FALSE, 
  crawlUrlfilter = filter, 
  NetworkData = TRUE, statslinks = TRUE
)

INDEX$Url

