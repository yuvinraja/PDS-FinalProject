# ============================================================================
# PHASE 2: EDA & ANALYSIS
# Loading and analyzing all three data sources
# ============================================================================

# --- 1. Install and Load Packages ---
if (!require("dplyr")) install.packages("dplyr")
if (!require("tidytext")) install.packages("tidytext")
if (!require("stringr")) install.packages("stringr")
if (!require("ggplot2")) install.packages("ggplot2")

library(dplyr)
library(tidytext)
library(stringr)
library(ggplot2)

# --- 2. Load All Three Data Sources ---

# Source 1: Policy (from McKinsey PDF)
policy_words <- read.csv("policy_word_counts.csv")

# Source 2: Job Market (from RemoteOK API)
job_market_data <- read.csv("job_market_data.csv")

# Source 3: Workforce Sentiment (from Reddit)
workforce_comments <- read.csv("comments.csv")


# --- 3. Analyze Source 2 (Job Market Data) ---

# Find the top 10 companies hiring for AI roles
top_companies <- job_market_data %>%
  count(company, sort = TRUE) %>%
  head(10)

print("--- Top 10 Companies Hiring for AI Roles ---")
print(top_companies)

# Find the top 10 most common AI job titles
# We clean up the titles a bit first
top_positions <- job_market_data %>%
  mutate(position_clean = str_to_lower(position) %>% 
           str_remove("senior|sr\\.|junior|jr\\.") %>% # Remove seniority
           str_remove("\\(remote\\)|remote") %>%       # Remove remote
           str_trim()                                 # Remove whitespace
  ) %>%
  count(position_clean, sort = TRUE) %>%
  head(10)

print("--- Top 10 AI Job Positions ---")
print(top_positions)


# --- 4. Analyze Source 3 (Workforce Sentiment Data) ---

# Load stop_words (e.g., "the", "a", "is")
data("stop_words")

# Tokenize, clean, and count words from Reddit comments
workforce_words <- workforce_comments %>%
  unnest_tokens(word, comment_text) %>%
  anti_join(stop_words, by = "word") %>%
  # Remove common unhelpful words
  filter(!word %in% c("ai", "chatgpt", "like", "it's", "using", "use", "code", "really")) %>%
  count(word, sort = TRUE)

print("--- Top 20 Words from Workforce Comments ---")
print(head(workforce_words, 20))

# Perform a quick sentiment analysis
# We use the "bing" lexicon (positive/negative)
bing_sentiments <- get_sentiments("bing")

sentiment_analysis <- workforce_comments %>%
  unnest_tokens(word, comment_text) %>%
  inner_join(bing_sentiments, by = "word") %>%
  count(sentiment) # Count total positive vs. negative words

print("--- Overall Workforce Sentiment ---")
print(sentiment_analysis)


# --- 5. Save Analyzed Data for Shiny App ---

# We save these new, summarized data frames.
# Our Shiny app will be much faster if it loads these small files
# instead of re-processing the raw data every time.

write.csv(top_companies, "shiny_top_companies.csv", row.names = FALSE)
write.csv(top_positions, "shiny_top_positions.csv", row.names = FALSE)
write.csv(workforce_words, "shiny_workforce_words.csv", row.names = FALSE)
write.csv(sentiment_analysis, "shiny_sentiment.csv", row.names = FALSE)
# We also still have our 'policy_words' data frame from Phase 1.

cat("\n=== Phase 2 (EDA) Complete ===\n")
cat("All data has been analyzed and summarized.\n")
cat("New files saved: 'shiny_top_companies.csv', 'shiny_top_positions.csv', 'shiny_workforce_words.csv', 'shiny_sentiment.csv'\n")