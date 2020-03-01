library(dplyr)
library(purrr)
library(stringr)
library(aws.s3)
library(glue)
library(fs)

if (Sys.getenv("AWS_ACCESS_KEY_ID") == ""  || Sys.getenv("AWS_SECRET_ACCESS_KEY") == "" ) {
  stop("You must provide AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables")
}

extract_csv <- function(x){
  m <- readLines(x) %>% str_extract("https://.*?\\.(CSV|csv)")
  if(all(is.na(m))) return(tibble(file = x, matches = NA))
  z <- m[!is.na(m)]
  tibble(file = x, matches = z)
}

# find last modification time of all nhs digital files, then extract folder name
data_folder <- 
  fs::dir_info(glob = "digital.nhs.uk-*", recursive = TRUE) %>% 
  filter(modification_time == max(modification_time)) %>% 
  pluck("path") %>% 
  dirname()
data_folder

to_extract <- list.files(data_folder, full.names = TRUE)
to_extract

# extract_csv(to_extract)


pretty_name <- function(x){
  # str_extract(x, "T[[:digit:]]{6}.*.(CSV|csv)") %>% 
  x %>% 
    str_replace("https://.*/", "") %>% 
    str_replace("%20", "_") %>% tolower()
}

csv_list <-
  list.files(data_folder, full.names = TRUE) %>% 
  map_dfr(extract_csv) %>% 
  filter(
    !is.na(matches)
  ) %>% 
  mutate(
    filename = pretty_name(matches)
  )

csv_list

bucket_list <- 
  aws.s3::get_bucket_df(
    prefix = "practice-level",
    bucket = "nhs-prescription-data",
    region = "us-west-2"
  ) %>% 
  as_tibble() %>% 
  select(Key, LastModified, Size) %>% 
  filter(Size != "0") %>% 
  mutate(filename = gsub("practice-level/", "", Key))

csv_list$filename %in% bucket_list$filename

new_files <-
  csv_list %>% 
  dplyr::anti_join(bucket_list, by = "filename")
new_files



process_csv <- function(x){
  
  in_file <- tempfile(fileext = ".csv")
  out_file <- tempfile(fileext = ".csv")
  
  on.exit({
    unlink(in_file)
    unlink(out_file)
  })
  
  new_name <- pretty_name(x)
  message(new_name)
  
  z <- tryCatch(
    download.file(x, destfile = in_file),
    error = function(e)e
  )
  if(inherits(z, "error")) return(data.frame(x = x, results = "download error"))
  
  cmd <- glue::glue("sed 's/, *$//' {in_file} > {out_file}")

  z <- tryCatch(
    system(cmd),
    error = function(e)e
  )
  if(inherits(z, "error")) return(data.frame(x = x, results = "sed error"))
  
  z <- tryCatch(
    aws.s3::put_object(
      out_file, 
      object = glue::glue("practice-level/{new_name}"),
      bucket = "nhs-prescription-data",
      region = "us-west-2",
      multipart = TRUE,
      show_progress = TRUE
    ),
    error = function(e)e
  )
  if(inherits(z, "error")) return(data.frame(x = x, results = "aws.s3 error"))
  
  data.frame(x = new_name, results = "OK")
}


new_files$matches %>% 
  map_dfr(process_csv)


