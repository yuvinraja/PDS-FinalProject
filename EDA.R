if (!require("dplyr")) install.packages("dplyr")
if (!require("tidytext")) install.packages("tidytext")
if (!require("stringr")) install.packages("stringr")
if (!require("ggplot2")) install.packages("ggplot2")

library(dplyr)
library(tidytext)
library(stringr)
library(ggplot2)
policy_words <- read.csv("policy_word_counts.csv")
job_market_data <- read.csv("job_market_data.csv")
workforce_comments <- read.csv("comments.csv")
top_companies <- job_market_data %>%
  count(company, sort = TRUE) %>%
  head(10)

print("--- Top 10 Companies Hiring for AI Roles ---")
print(top_companies)
top_positions <- job_market_data %>%
  mutate(position_clean = str_to_lower(position) %>% 
           str_remove("senior|sr\\.|junior|jr\\.") %>%
           str_remove("\\(remote\\)|remote") %>%
           str_trim()
  ) %>%
  count(position_clean, sort = TRUE) %>%
  head(10)

print("--- Top 10 AI Job Positions ---")
print(top_positions)
data("stop_words")
workforce_words <- workforce_comments %>%
  unnest_tokens(word, comment_text) %>%
  anti_join(stop_words, by = "word") %>%
  filter(!word %in% c("ai", "chatgpt", "like", "it's", "using", "use", "code", "really")) %>%
  count(word, sort = TRUE)

print("--- Top 20 Words from Workforce Comments ---")
print(head(workforce_words, 20))
bing_sentiments <- get_sentiments("bing")

sentiment_analysis <- workforce_comments %>%
  unnest_tokens(word, comment_text) %>%
  inner_join(bing_sentiments, by = "word") %>%
  count(sentiment)

print("--- Overall Workforce Sentiment ---")
print(sentiment_analysis)

write.csv(top_companies, "shiny_top_companies.csv", row.names = FALSE)
write.csv(top_positions, "shiny_top_positions.csv", row.names = FALSE)
write.csv(workforce_words, "shiny_workforce_words.csv", row.names = FALSE)
write.csv(sentiment_analysis, "shiny_sentiment.csv", row.names = FALSE)

cat("\n=== Phase 2 (EDA) Complete ===\n")
cat("All data has been analyzed and summarized.\n")
cat("New files saved: 'shiny_top_companies.csv', 'shiny_top_positions.csv', 'shiny_workforce_words.csv', 'shiny_sentiment.csv'\n")