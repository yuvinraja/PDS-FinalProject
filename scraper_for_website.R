# --- 1. Install and Load Required Packages ---

# Install jsonlite to work with the API
if (!require("jsonlite")) install.packages("jsonlite")
library(jsonlite)

# Install dplyr for data manipulation
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)

# Install stringr for text filtering
if (!require("stringr")) install.packages("stringr")
library(stringr)

# --- 2. Call the API and Get Data ---

# Define the API URL
api_url <- "https://remoteok.com/api/"

# Read the JSON data from the API
# This function fetches the data and parses it into R objects
raw_data <- fromJSON(api_url)

# The first row is a legal notice, so we skip it
# We convert the list of jobs into a single data frame
jobs_df <- raw_data[-1, ] 

# --- 3. Clean and Filter the "Reality" Job Data ---

# Select only the columns we care about
jobs_clean <- jobs_df %>%
  select(date, company, position, description, tags, location) %>%
  # The 'tags' column is a list, convert it to a single string
  rowwise() %>%
  mutate(tags_flat = paste(unlist(tags), collapse = ", ")) %>%
  ungroup()

# Filter for AI-related jobs
# We search the position, description, and tags for our keywords
ai_jobs <- jobs_clean %>%
  filter(
    # 'str_detect' searches for a pattern. 'tolower' makes it case-insensitive.
    str_detect(tolower(position), "ai|generative|llm") |
      str_detect(tolower(description), "ai|generative|llm") |
      str_detect(tolower(tags_flat), "ai|generative|llm")
  ) %>%
  # Select the final columns to save
  select(date, company, position, location, description)

# --- 4. View Results and Save to CSV ---

# Print the first few AI jobs found
print("--- Found the following AI-related jobs: ---")
print(head(ai_jobs))

# Print a summary
cat(paste("\nFound", nrow(ai_jobs), "AI-related jobs out of", nrow(jobs_clean), "total postings.\n"))

# Save the structured data to a CSV file
write.csv(ai_jobs, "job_market_data.csv", row.names = FALSE)

cat("Successfully saved AI job data to 'job_market_data.csv'\n")