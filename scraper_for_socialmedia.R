library(httr2)
library(jsonlite)
library(dplyr)
library(stringr)

setup_reddit_auth <- function() {
  client_id <- "JIZa2v_WCmNm6wjSw64odg"
  client_secret <- "9ivXejeVn-BA-e7pq_WiPgls6Qn4HA"
  
  if (client_id == "YOUR_CLIENT_ID_HERE" || client_secret == "YOUR_CLIENT_SECRET_HERE") {
    cat("⚠️ SETUP REQUIRED:\n")
    cat("1. Go to https://www.reddit.com/prefs/apps\n")
    cat("2. Create a 'script' app\n")
    cat("3. Copy your Client ID and Client Secret into the script\n")
    return(NULL)
  }
  
  user_agent <- "GenAIWorkplaceResearch/1.0"
  auth_url <- "https://www.reddit.com/api/v1/access_token"
  
  tryCatch({
    token_response <- httr2::request(auth_url) %>%
      httr2::req_auth_basic(client_id, client_secret) %>%
      httr2::req_headers("User-Agent" = user_agent) %>%
      httr2::req_body_form(grant_type = "client_credentials") %>%
      httr2::req_perform()
    
    token_data <- httr2::resp_body_string(token_response) %>%
      jsonlite::fromJSON()
    
    if (!is.null(token_data$error)) {
      cat("Authentication failed:", token_data$error, "\n")
      return(NULL)
    }
    
    access_token <- token_data$access_token
    cat("✓ Reddit authentication successful\n")
    return(access_token)
    
  }, error = function(e) {
    cat("Authentication error:", e$message, "\n")
    return(NULL)
  })
}

fetch_reddit_thread_comments <- function(subreddit, post_id, access_token, 
                                         sort = "best", limit = 500) {
  cat("\nFetching comments from thread...\n")
  url <- paste0(
    "https://oauth.reddit.com/r/", subreddit, "/comments/", post_id,
    "?sort=", sort, "&limit=", limit
  )
  
  tryCatch({
    response <- httr2::request(url) %>%
      httr2::req_headers(
        "Authorization" = paste("bearer", access_token),
        "User-Agent" = "GenAIWorkplaceResearch/1.0"
      ) %>%
      httr2::req_timeout(15) %>%
      httr2::req_perform()
    
    data <- httr2::resp_body_string(response) %>%
      jsonlite::fromJSON(flatten = TRUE, simplifyVector = FALSE)
    
    if (length(data) < 2 || is.null(data[[2]]$data$children)) {
      stop("Invalid Reddit API structure or no comments returned.")
    }
    
    comments_data <- data[[2]]$data$children
    
    comments_list <- lapply(comments_data, function(x) x$data)
    comments_df <- bind_rows(comments_list)
    
    comments_df <- comments_df %>%
      filter(!is.na(body), body != "[deleted]", body != "[removed]") %>%
      filter(str_count(body, "\\w+") > 5) %>%
      select(
        comment_id = id,
        author,
        comment_text = body,
        score,
        created_utc
      )
    
    cat("✓ Collected", nrow(comments_df), "raw comments\n")
    return(comments_df)
    
  }, error = function(e) {
    cat("Error fetching thread:", e$message, "\n")
    return(NULL)
  })
}

filter_quality_comments <- function(comments_df) {
  cat("\nFiltering comments for quality...\n")
  
  if (is.null(comments_df) || nrow(comments_df) == 0) {
    stop("No comments to filter.")
  }
  
  filtered_df <- comments_df %>%
    mutate(comment_text = as.character(comment_text)) %>%
    filter(!str_detect(tolower(comment_text), "^(lol|this|first|edit:|thanks for gold)")) %>%
    filter(nchar(comment_text) > 50) %>%
    filter(score >= 5) %>%
    arrange(desc(score)) %>%
    slice_head(n = 100)
  
  cat("✓ Filtered down to", nrow(filtered_df), "high-quality comments\n")
  return(filtered_df)
}

main_collection <- function() {
  cat("\n=== STEP 3: REDDIT COMMENT COLLECTION ===\n")
  cat("Step 1: Authenticating with Reddit API...\n")
  access_token <- setup_reddit_auth()
  
  if (is.null(access_token)) {
    return(NULL)
  }
  
  cat("\nStep 2: Fetching comments from thread...\n")
  raw_comments <- fetch_reddit_thread_comments(
    subreddit = "cscareerquestions",
    post_id = "1e8pqua",
    access_token = access_token
  )
  
  if (is.null(raw_comments) || nrow(raw_comments) == 0) {
    cat("No comments were fetched. Exiting.\n")
    return(NULL)
  }
  cat("\nStep 3: Filtering for quality comments...\n")
  quality_comments <- filter_quality_comments(raw_comments)
  
  cat("\nStep 4: Saving results...\n")
  final_comments_to_save <- quality_comments %>%
    select(comment_text)
  
  write.csv(
    final_comments_to_save,
    "comments.csv", # Saved as comments.csv
    row.names = FALSE
  )
  
  cat("✓ Successfully saved", nrow(final_comments_to_save), "comments to 'comments.csv'\n")
  cat("\n=== COLLECTION COMPLETE ===\n")
  return(quality_comments)
}
result <- main_collection()