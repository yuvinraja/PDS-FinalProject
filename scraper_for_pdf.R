if (!require("pdftools")) install.packages("pdftools")
library(pdftools)
if (!require("tidytext")) install.packages("tidytext")
library(tidytext)
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)
pdf_file_name <- "the-economic-potential-of-generative-ai-the-next-productivity-frontier.pdf"
pdf_text <- pdf_text(pdf_file_name)
pdf_df <- data.frame(
  page_number = 1:length(pdf_text),
  text = pdf_text
)
pdf_words <- pdf_df %>%
  unnest_tokens(word, text)
data("stop_words")
cleaned_pdf_words <- pdf_words %>%
  anti_join(stop_words, by = "word")
top_pdf_words <- cleaned_pdf_words %>%
  count(word, sort = TRUE)
print("Top 20 most frequent words in the McKinsey report:")
print(head(top_pdf_words, 20))
write.csv(top_pdf_words, "policy_word_counts.csv", row.names = FALSE)

cat("\nSuccessfully processed the PDF and saved the word counts to 'policy_word_counts.csv'\n")