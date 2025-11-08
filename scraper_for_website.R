if (!require("jsonlite")) install.packages("jsonlite")
library(jsonlite)
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)
if (!require("stringr")) install.packages("stringr")
library(stringr)
api_url <- "https://remoteok.com/api/"
raw_data <- fromJSON(api_url)
jobs_df <- raw_data[-1, ] 
jobs_clean <- jobs_df %>%
  select(date, company, position, description, tags, location) %>%
  rowwise() %>%
  mutate(tags_flat = paste(unlist(tags), collapse = ", ")) %>%
  ungroup()
ai_jobs <- jobs_clean %>%
  filter(
    str_detect(tolower(position), "ai|generative|llm") |
      str_detect(tolower(description), "ai|generative|llm") |
      str_detect(tolower(tags_flat), "ai|generative|llm")
  ) %>%
  select(date, company, position, location, description)
print("--- Found the following AI-related jobs: ---")
print(head(ai_jobs))
cat(paste("\nFound", nrow(ai_jobs), "AI-related jobs out of", nrow(jobs_clean), "total postings.\n"))
write.csv(ai_jobs, "job_market_data.csv", row.names = FALSE)

cat("Successfully saved AI job data to 'job_market_data.csv'\n")