library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(wordcloud2)
library(DT)
library(dplyr)
library(stringr)

policy_words <- read.csv("policy_word_counts.csv")
top_companies <- read.csv("shiny_top_companies.csv")
top_positions <- read.csv("shiny_top_positions.csv")
workforce_words <- read.csv("shiny_workforce_words.csv")
sentiment_data <- read.csv("shiny_sentiment.csv")
raw_comments <- read.csv("comments.csv") # The "ideal" raw comments

total_jobs <- sum(top_companies$n)
top_policy_word <- policy_words[1, "word"]
top_workforce_word <- workforce_words[1, "word"]

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "GenAI @ Work"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Job Market Analysis", tabName = "job_market", icon = icon("chart-line")),
      menuItem("Workforce Sentiment", tabName = "sentiment", icon = icon("comments"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "overview",
        fluidRow(
          valueBox(
            value = str_to_title(top_policy_word),
            subtitle = "Top Policy Term",
            icon = icon("landmark"),
            color = "aqua"
          ),
          valueBox(
            value = str_to_title(top_workforce_word),
            subtitle = "Top Workforce Term",
            icon = icon("users"),
            color = "yellow"
          ),
          valueBox(
            value = total_jobs,
            subtitle = "Total AI Jobs",
            icon = icon("briefcase"),
            color = "green"
          )
        ),
        fluidRow(
          box(
            title = "Policy Focus",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            wordcloud2Output("policy_wordcloud")
          ),
          box(
            title = "Workforce Focus",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            wordcloud2Output("workforce_wordcloud")
          )
        )
      ),
      tabItem(
        tabName = "job_market",
        fluidRow(
          box(
            title = "Top AI Job Titles",
            status = "info",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("positions_plot")
          ),
          box(
            title = "Top Hiring Companies",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            DT::dataTableOutput("companies_table")
          )
        )
      ),
      tabItem(
        tabName = "sentiment",
        fluidRow(
          box(
            title = "Sentiment Breakdown",
            status = "success",
            solidHeader = TRUE,
            width = 5,
            plotlyOutput("sentiment_plot")
          ),
          box(
            title = "Sample Comments",
            status = "success",
            solidHeader = TRUE,
            width = 7,
            DT::dataTableOutput("raw_comments_table")
          )
        )
      )
    )
  )
)

server <- function(input, output) {
  output$policy_wordcloud <- renderWordcloud2({
    wordcloud2(data = policy_words, size = 0.8, color = "random-dark")
  })
  output$workforce_wordcloud <- renderWordcloud2({
    wordcloud2(data = workforce_words, size = 1.0, color = "random-light")
  })
  output$positions_plot <- renderPlotly({
    plot_ly(
      data = top_positions,
      x = ~n,
      y = ~reorder(str_to_title(position_clean), n),
      type = "bar",
      orientation = "h",
      marker = list(color = "#1f77b4")
    ) %>%
      layout(
        title = "Top 10 AI Job Titles",
        yaxis = list(title = ""),
        xaxis = list(title = "Number of Postings")
      )
  })
  output$companies_table <- DT::renderDataTable({
    datatable(
      top_companies,
      options = list(pageLength = 10, searching = FALSE, dom = "t"),
      rownames = FALSE,
      colnames = c("Company" = "company", "Jobs" = "n")
    )
  })
  output$sentiment_plot <- renderPlotly({
    plot_ly(
      data = sentiment_data,
      labels = ~str_to_title(sentiment),
      values = ~n,
      type = "pie",
      textinfo = "label+percent",
      insidetextorientation = "radial",
      marker = list(colors = c("Negative" = "#d9534f", "Positive" = "#5cb85c"))
    ) %>%
      layout(title = "Sentiment of Reddit Comments")
  })
  output$raw_comments_table <- DT::renderDataTable({
    datatable(
      raw_comments,
      options = list(pageLength = 5, searching = TRUE),
      rownames = FALSE,
      colnames = c("Comment Text" = "comment_text")
    )
  })
}
shinyApp(ui = ui, server = server)