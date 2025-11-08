# ============================================================================
# PHASE 3: SHINY WEB APP
# File: app.R
# This script loads your *CLEAN* CSVs and builds the interactive dashboard.
# ============================================================================

# --- 1. Load All Required Packages ---
# You may need to install these first
# install.packages("shiny")
# install.packages("plotly")
# install.packages("ggplot2")
# install.packages("wordcloud2")
# install.packages("DT")
# install.packages("dplyr")

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(wordcloud2)
library(DT) # For interactive tables

# ============================================================================
# --- 2. Load Your FOUR Clean Datasets ---
# Shiny will load these files when it starts.
# Make sure they are in the same directory as this app.R file.
# ============================================================================

# We also load the policy_word_counts.csv from Step 1
policy_words <- read.csv("policy_word_counts.csv")
top_companies <- read.csv("shiny_top_companies.csv")
top_positions <- read.csv("shiny_top_positions.csv")
workforce_words <- read.csv("shiny_workforce_words.csv")
sentiment_data <- read.csv("shiny_sentiment.csv")

# ============================================================================
# --- 3. Define the UI (User Interface) ---
# This controls the layout, tabs, and what the user sees.
# ============================================================================
ui <- fluidPage(
  titlePanel(HTML("Generative AI in the Workplace:<br/>Policy vs. Reality")), # Title
  
  # Create a tabbed layout
  tabsetPanel(
    
    # --- TAB 1: POLICY vs. REALITY (The Main Story) ---
    tabPanel("Policy vs. Reality",
             fluidRow(
               column(6,
                      h3("The 'Policy' View (McKinsey Report)"),
                      p("This word cloud shows the most common terms from the McKinsey report. It focuses on high-level concepts like 'productivity', 'economic', and 'potential'."),
                      wordcloud2Output("policy_wordcloud")
               ),
               column(6,
                      h3("The 'Workforce' View (Reddit Comments)"),
                      p("This word cloud shows the most common terms from tech workers. The discussion is much more grounded, focusing on 'time', 'learning', and 'writing code'."),
                      wordcloud2Output("workforce_wordcloud")
               )
             )
    ),
    
    # --- TAB 2: JOB MARKET (Source 2) ---
    tabPanel("Job Market Analysis (API Data)",
             sidebarLayout(
               sidebarPanel(
                 h3("Top AI-Related Hirers"),
                 p("Companies found actively hiring for AI-related roles, based on data from the RemoteOK API."),
                 DT::dataTableOutput("companies_table") # Interactive table
               ),
               mainPanel(
                 h3("Most Common Job Titles"),
                 p("These are the most frequent job titles found in the AI-related postings."),
                 plotlyOutput("positions_plot") # Bar chart
               )
             )
    ),
    
    # --- TAB 3: WORKFORCE SENTIMENT (Source 3) ---
    tabPanel("Workforce Sentiment (Reddit Data)",
             fluidRow(
               column(6,
                      h3("Overall Sentiment"),
                      p("Sentiment analysis of 30 Reddit comments. This shows the balance of positive vs. negative words used in the discussion."),
                      plotlyOutput("sentiment_plot") # Pie chart
               ),
               column(6,
                      h3("Top Topics of Discussion"),
                      p("This is the same word cloud from the first tab, showing the key topics from the workforce perspective."),
                      wordcloud2Output("workforce_wordcloud_tab3") # Duplicate word cloud
               )
             )
    )
  )
)

# ============================================================================
# --- 4. Define the SERVER (The Logic) ---
# This builds the plots and tables to fill the UI.
# ============================================================================
server <- function(input, output) {
  
  # --- TAB 1: POLICY vs. REALITY ---
  
  # Render the "Policy" word cloud
  output$policy_wordcloud <- renderWordcloud2({
    # We filter for more meaningful words (n > 10)
    wordcloud_data <- filter(policy_words, n > 10 & word != "al")
    wordcloud2(data = wordcloud_data, size = 0.8, color = "random-dark")
  })
  
  # Render the "Workforce" word cloud
  output$workforce_wordcloud <- renderWordcloud2({
    # We can use a lower 'n' here since we have less data
    wordcloud_data <- filter(workforce_words, n >= 2)
    wordcloud2(data = wordcloud_data, size = 1.0, color = "random-light")
  })
  
  # --- TAB 2: JOB MARKET ---
  
  # Render the top companies table
  output$companies_table <- DT::renderDataTable({
    datatable(top_companies, options = list(pageLength = 10, searching = FALSE))
  })
  
  # Render the top positions bar chart
  output$positions_plot <- renderPlotly({
    plot_ly(
      data = top_positions,
      x = ~n,
      y = ~reorder(position_clean, n), # Sort by count
      type = "bar",
      orientation = "h",
      marker = list(color = '#1f77b4')
    ) %>%
      layout(
        title = "Top 10 AI Job Titles",
        yaxis = list(title = ""),
        xaxis = list(title = "Number of Postings")
      )
  })
  
  # --- TAB 3: WORKFORCE SENTIMENT ---
  
  # Render the sentiment pie chart
  output$sentiment_plot <- renderPlotly({
    plot_ly(
      data = sentiment_data,
      labels = ~stringr::str_to_title(sentiment), # Capitalize labels
      values = ~n,
      type = "pie",
      textinfo = "label+percent",
      insidetextorientation = "radial",
      marker = list(colors = c('negative' = '#d9534f', 'positive' = '#5cb85c'))
    ) %>%
      layout(title = "Sentiment of Reddit Comments")
  })
  
  # Render the workforce word cloud (a copy for this tab)
  output$workforce_wordcloud_tab3 <- renderWordcloud2({
    wordcloud_data <- filter(workforce_words, n >= 2)
    wordcloud2(data = wordcloud_data, size = 1.0, color = "random-light")
  })
  
}

# ============================================================================
# --- 5. Run the Application ---
# ============================================================================
shinyApp(ui = ui, server = server)