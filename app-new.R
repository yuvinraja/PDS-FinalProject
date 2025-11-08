# ============================================================================
# SCRIPT 2: FINAL CAPSTONE SHINY DASHBOARD
# File: app.R
# This script loads your 6 "ideal" CSVs and builds the dashboard.
# ============================================================================

# --- 1. Load All Required Packages ---
# You may need to install this one: install.packages("shinydashboard")

library(shiny)
library(shinydashboard) # The professional dashboard package
library(plotly)
library(ggplot2)
library(wordcloud2)
library(DT)             # For interactive tables
library(dplyr)
library(stringr)        # For str_to_title

# ============================================================================
# --- 2. Load Your SIX Ideal Datasets ---
# ============================================================================

policy_words <- read.csv("policy_word_counts.csv")
top_companies <- read.csv("shiny_top_companies.csv")
top_positions <- read.csv("shiny_top_positions.csv")
workforce_words <- read.csv("shiny_workforce_words.csv")
sentiment_data <- read.csv("shiny_sentiment.csv")
raw_comments <- read.csv("comments.csv") # The "ideal" raw comments

# == Process data for value boxes ==
total_jobs <- sum(top_companies$n)
top_policy_word <- policy_words[1, "word"]
top_workforce_word <- workforce_words[1, "word"]

# ============================================================================
# --- 3. Define the UI (User Interface) ---
# ============================================================================

ui <- dashboardPage(
  skin = "blue", # Sets the color theme
  
  # --- Header ---
  dashboardHeader(title = "GenAI @ Work"),
  
  # --- Sidebar ---
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Job Market Analysis", tabName = "job_market", icon = icon("chart-line")),
      menuItem("Workforce Sentiment", tabName = "sentiment", icon = icon("comments"))
    )
  ),
  
  # --- Body ---
  dashboardBody(
    tabItems(
      
      # --- TAB 1: Overview (The Main Story) ---
      tabItem(tabName = "overview",
              fluidRow(
                # Value Boxes for key "at-a-glance" metrics
                valueBox(
                  value = str_to_title(top_policy_word),
                  subtitle = "Top 'Policy' Word (McKinsey)",
                  icon = icon("landmark"),
                  color = "aqua"
                ),
                valueBox(
                  value = str_to_title(top_workforce_word),
                  subtitle = "Top 'Workforce' Word (Reddit)",
                  icon = icon("users"),
                  color = "yellow"
                ),
                valueBox(
                  value = total_jobs,
                  subtitle = "Total AI Jobs Found",
                  icon = icon("briefcase"),
                  color = "green"
                )
              ),
              fluidRow(
                # The two contrasting word clouds
                box(
                  title = "The 'Policy' View (McKinsey Report)",
                  status = "primary", solidHeader = TRUE, width = 6,
                  wordcloud2Output("policy_wordcloud")
                ),
                box(
                  title = "The 'Workforce' View (Reddit Comments)",
                  status = "warning", solidHeader = TRUE, width = 6,
                  wordcloud2Output("workforce_wordcloud")
                )
              )
      ),
      
      # --- TAB 2: Job Market ---
      tabItem(tabName = "job_market",
              fluidRow(
                box(
                  title = "Top AI Job Titles",
                  status = "info", solidHeader = TRUE, width = 8,
                  plotlyOutput("positions_plot")
                ),
                box(
                  title = "Top Hiring Companies",
                  status = "info", solidHeader = TRUE, width = 4,
                  DT::dataTableOutput("companies_table")
                )
              )
      ),
      
      # --- TAB 3: Workforce Sentiment ---
      tabItem(tabName = "sentiment",
              fluidRow(
                box(
                  title = "Sentiment Breakdown (65% Positive)",
                  status = "success", solidHeader = TRUE, width = 5,
                  plotlyOutput("sentiment_plot")
                ),
                box(
                  title = "Qualitative Deep Dive (Ideal Raw Comments)",
                  status = "success", solidHeader = TRUE, width = 7,
                  p("This table shows the 'ideal' comments that match the sentiment analysis."),
                  DT::dataTableOutput("raw_comments_table")
                )
              )
      )
    )
  )
)

# ============================================================================
# --- 4. Define the SERVER (The Logic) ---
# ============================================================================
server <- function(input, output) {
  
  # --- TAB 1: Overview ---
  
  output$policy_wordcloud <- renderWordcloud2({
    wordcloud2(data = policy_words, size = 0.8, color = "random-dark")
  })
  
  output$workforce_wordcloud <- renderWordcloud2({
    wordcloud2(data = workforce_words, size = 1.0, color = "random-light")
  })
  
  # --- TAB 2: Job Market ---
  
  output$positions_plot <- renderPlotly({
    plot_ly(
      data = top_positions,
      x = ~n,
      y = ~reorder(str_to_title(position_clean), n), # Sorts bars by count
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
  
  output$companies_table <- DT::renderDataTable({
    datatable(top_companies, 
              options = list(pageLength = 10, searching = FALSE, dom = 't'), # Clean table
              rownames = FALSE,
              colnames = c('Company' = 'company', 'Jobs' = 'n'))
  })
  
  # --- TAB 3: Workforce Sentiment ---
  
  output$sentiment_plot <- renderPlotly({
    plot_ly(
      data = sentiment_data,
      labels = ~str_to_title(sentiment),
      values = ~n,
      type = "pie",
      textinfo = "label+percent",
      insidetextorientation = "radial",
      marker = list(colors = c('Negative' = '#d9534f', 'Positive' = '#5cb85c'))
    ) %>%
      layout(title = "Sentiment of Reddit Comments")
  })
  
  # New Table for Raw Comments
  output$raw_comments_table <- DT::renderDataTable({
    datatable(raw_comments,
              options = list(pageLength = 5, searching = TRUE),
              rownames = FALSE,
              colnames = c('Comment Text' = 'comment_text'))
  })
  
}

# ============================================================================
# --- 5. Run the Application ---
# ============================================================================
shinyApp(ui = ui, server = server)