library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(wordcloud2)
library(DT)

policy_words <- read.csv("policy_word_counts.csv")
top_companies <- read.csv("shiny_top_companies.csv")
top_positions <- read.csv("shiny_top_positions.csv")
workforce_words <- read.csv("shiny_workforce_words.csv")
sentiment_data <- read.csv("shiny_sentiment.csv")
ui <- fluidPage(
  titlePanel(HTML("Generative AI in the Workplace:<br/>Policy vs. Reality")),
  tabsetPanel(
    tabPanel(
      "Policy vs. Reality",
      fluidRow(
        column(
          6,
          h3("Policy View"),
          wordcloud2Output("policy_wordcloud")
        ),
        column(
          6,
          h3("Workforce View"),
          wordcloud2Output("workforce_wordcloud")
        )
      )
    ),
    tabPanel(
      "Job Market Analysis (API Data)",
      sidebarLayout(
        sidebarPanel(
          h3("Top Hirers"),
          DT::dataTableOutput("companies_table")
        ),
        mainPanel(
          h3("Most Common Job Titles"),
          plotlyOutput("positions_plot")
        )
      )
    ),
    tabPanel(
      "Workforce Sentiment (Reddit Data)",
      fluidRow(
        column(
          6,
          h3("Overall Sentiment"),
          plotlyOutput("sentiment_plot")
        ),
        column(
          6,
          h3("Key Topics"),
          wordcloud2Output("workforce_wordcloud_tab3")
        )
      )
    )
  )
)
server <- function(input, output) {
  output$policy_wordcloud <- renderWordcloud2({
    wordcloud_data <- filter(policy_words, n > 10 & word != "al")
    wordcloud2(data = wordcloud_data, size = 0.8, color = "random-dark")
  })
  output$workforce_wordcloud <- renderWordcloud2({
    wordcloud_data <- filter(workforce_words, n >= 2)
    wordcloud2(data = wordcloud_data, size = 1.0, color = "random-light")
  })
  output$companies_table <- DT::renderDataTable({
    datatable(top_companies, options = list(pageLength = 10, searching = FALSE))
  })
  output$positions_plot <- renderPlotly({
    plot_ly(
      data = top_positions,
      x = ~n,
      y = ~reorder(position_clean, n),
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
  output$sentiment_plot <- renderPlotly({
    plot_ly(
      data = sentiment_data,
      labels = ~stringr::str_to_title(sentiment),
      values = ~n,
      type = "pie",
      textinfo = "label+percent",
      insidetextorientation = "radial",
      marker = list(colors = c("negative" = "#d9534f", "positive" = "#5cb85c"))
    ) %>%
      layout(title = "Sentiment of Reddit Comments")
  })
  output$workforce_wordcloud_tab3 <- renderWordcloud2({
    wordcloud_data <- filter(workforce_words, n >= 2)
    wordcloud2(data = wordcloud_data, size = 1.0, color = "random-light")
  })
}
shinyApp(ui = ui, server = server)