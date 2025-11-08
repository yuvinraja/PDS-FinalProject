# --- 1. Install and Load Required Packages ---

# Install pdftools to read the PDF
if (!require("pdftools")) install.packages("pdftools")
library(pdftools)

# Install tidytext for text analysis
if (!require("tidytext")) install.packages("tidytext")
library(tidytext)

# Install dplyr for data manipulation
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)

# --- 2. Load and Read the PDF ---

# Define the file name
# Make sure this PDF is in the same directory as your R script
pdf_file_name <- "the-economic-potential-of-generative-ai-the-next-productivity-frontier.pdf"

# Extract all text from the PDF
# This creates a long list of text, one item per page
pdf_text <- pdf_text(pdf_file_name)

# --- 3. Convert PDF Text into a Tidy Data Frame ---

# Convert the text list into a data frame
# We add a 'page_number' for reference
pdf_df <- data.frame(
  page_number = 1:length(pdf_text),
  text = pdf_text
)

# --- 4. Analyze the "Policy" Language (EDA) ---

# Use unnest_tokens() to break the text into individual words
pdf_words <- pdf_df %>%
  unnest_tokens(word, text)

# Load the built-in 'stop_words' dataset (e.g., "the", "a", "is")
data("stop_words")

# Remove the stop words to find the *meaningful* words
cleaned_pdf_words <- pdf_words %>%
  anti_join(stop_words, by = "word")

# Count the most common words in the entire report
top_pdf_words <- cleaned_pdf_words %>%
  count(word, sort = TRUE)

# --- 5. View Your Results ---

# Print the top 20 most common words from the McKinsey report
print("Top 20 most frequent words in the McKinsey report:")
print(head(top_pdf_words, 20))

# --- 6. Save Your Analyzed Data (Optional but Recommended) ---
# We will use this file later in the Shiny app
write.csv(top_pdf_words, "policy_word_counts.csv", row.names = FALSE)

cat("\nSuccessfully processed the PDF and saved the word counts to 'policy_word_counts.csv'\n")