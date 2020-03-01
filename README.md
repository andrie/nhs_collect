
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nhs\_collect

<!-- badges: start -->

<!-- badges: end -->

This project scrapes the [NHS digital practise level prescribing
data](https://digital.nhs.uk/data-and-information/publications/statistical/practice-level-prescribing-data)
and creates a copy on AWS S3 storage.

## Environment variables

The code uploads the NHS data files to AWS S3 storage, and you must
specify the following environment variables, e.g. in your `.Renviron`
file:

    AWS_ACCESS_KEY_ID     = ********************
    AWS_SECRET_ACCESS_KEY = ****************************************
