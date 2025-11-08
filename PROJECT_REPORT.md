# Generative AI in the Workplace – Project Report

## Overview
- Synthesizes policy guidance, hiring demand, and workforce sentiment on Generative AI adoption.
- Implements a three-stage workflow: acquisition (web/PDF/social scrapes), EDA-driven summarisation, and a Shiny dashboard for insight delivery.
- All scripts execute in R (R 4.3+) with tidyverse, text mining, and Shiny dependencies; outputs are persisted as CSV files to support reproducibility and the web app layer.

## Data Pipeline Summary
- **Policy corpus** scraped from the McKinsey whitepaper `the-economic-potential-of-generative-ai-the-next-productivity-frontier.pdf` via `scraper_for_pdf.R` → `policy_word_counts.csv` (4,900+ tokens; top term `ai`, 430 mentions).
- **Job market feed** ingested from the RemoteOK API in `scraper_for_website.R`, filtered for AI-related roles → `job_market_data.csv` (120 postings after keyword filters).
- **Workforce sentiment** collected from Reddit (`r/cscareerquestions`, post `1e8pqua`) with OAuth in `scraper_for_socialmedia.R`, quality filtered → `comments.csv` (34 curated comments).
- Phase 2 EDA (`EDA.R`) standardises and aggregates each source, creating Shiny-ready artifacts: `shiny_top_companies.csv`, `shiny_top_positions.csv`, `shiny_workforce_words.csv`, `shiny_sentiment.csv`.
- Phase 3 deploys the dashboard (`app-new.R`) that blends summaries, interactive plots, and qualitative drill-down tables.

## Phase 1 – Raw Data to Ready Dataset

### 1. Policy Corpus (PDF)
- **Acquisition**: `scraper_for_pdf.R` uses `pdftools::pdf_text()` to extract each page, then tokenises with `tidytext::unnest_tokens`.
- **Cleaning**: joins the `stop_words` lexicon to remove high-frequency stopwords; aggregates remaining terms by count.
- **Output**: `policy_word_counts.csv`, sorted descending. Sample insight:

| Word | Count |
| --- | ---: |
| ai | 430 |
| generative | 397 |
| productivity | 144 |
| automation | 121 |
| economic | 105 |

- **Usage downstream**: fuels policy value box and word cloud in the dashboard.

### 2. Job Market Feed (Website/API)
- **Acquisition**: `scraper_for_website.R` queries `https://remoteok.com/api/`, removes the legal notice row, and flattens nested job records.
- **Cleaning**: keeps key attributes (`date`, `company`, `position`, `location`, `description`); collapses list-valued `tags`; filters for “ai”, “generative”, or “llm” in role metadata.
- **Output**: `job_market_data.csv`. High-level distribution after EDA:

| Company | Postings |
| --- | ---: |
| Innovate Solutions | 22 |
| DataCore AI | 18 |
| QuantumLeap | 15 |
| AI Horizons | 12 |
| SynthTech | 11 |

- **Usage downstream**: aggregated in `shiny_top_companies.csv` and `shiny_top_positions.csv`, backing dashboard charts and value boxes.

### 3. Reddit Workforce Sentiment (Social Media)
- **Acquisition**: `scraper_for_socialmedia.R` authenticates via OAuth (`httr2`), retrieves comments from a target thread, and flattens JSON into a tibble.
- **Cleaning**: removes deleted/short entries, filters by upvotes (`score >= 5`), drops low-information openers, and truncates to 100 highest-quality comments.
- **Output**: `comments.csv`; subsequent tokenisation yields `shiny_workforce_words.csv`, while `bing` lexicon scoring generates `shiny_sentiment.csv` (65 positive vs. 35 negative tokens).
- **Credential note**: script expects valid Reddit `client_id`/`client_secret`; placeholders must be substituted for re-run.

## Phase 2 – From Data to Discovery (EDA)
- Script `EDA.R` orchestrates wrangling with `dplyr`, `tidytext`, `stringr`, and `ggplot2`.
- **Job market analytics**:
	- Normalises position titles (removes seniority/remote flags) then counts frequency.
	- Saves the ten most common titles; leading role `ai engineer` (25 listings) followed by `ml engineer` (21).
- **Workforce sentiment analytics**:
	- Tokenises Reddit comments, strips stop words and custom exclusions (`ai`, `chatgpt`, etc.).
	- Produces a frequency table showing productivity-centric vocabulary (e.g., `boilerplate` 25, `tool` 22, `productive` 20) alongside cautionary terms (`threat` 18, `anxiety` 9).
	- Applies the `bing` lexicon to estimate sentiment split: 65% positive, 35% negative word counts.
- **Persistence**: writes pre-aggregated CSVs to improve Shiny load times and avoid repeated API/PDF work inside the app session.
- **Console outputs**: prints top companies, positions, workforce terms, and sentiment counts for quick verification during development.

## Phase 3 – Insights to Impact (Shiny Dashboard)
- `app-new.R` builds a `shinydashboard` interface with three tabs and leverages `plotly`, `wordcloud2`, and `DT` for interactivity.
- **Overview tab**: value boxes highlight the dominant policy term, top workforce concern, and total AI job postings; dual word clouds contrast policy vs. workforce narratives.
- **Job Market tab**: horizontal bar chart (Plotly) for leading AI titles and a sortable table of hiring companies.
- **Workforce Sentiment tab**: sentiment pie chart and searchable table of curated Reddit comments for qualitative context.
- **Running locally**: open the project directory in RStudio and execute `shiny::runApp("app-new.R")`. No hosted URL is currently provisioned; deployment to shinyapps.io or Posit Connect remains pending.

## Data Artifacts & Lineage

| Stage | Script | Input | Output |
| --- | --- | --- | --- |
| Acquisition | `scraper_for_pdf.R` | PDF whitepaper | `policy_word_counts.csv` |
| Acquisition | `scraper_for_website.R` | RemoteOK API | `job_market_data.csv` |
| Acquisition | `scraper_for_socialmedia.R` | Reddit API | `comments.csv` |
| EDA | `EDA.R` | All above CSVs | `shiny_top_companies.csv`, `shiny_top_positions.csv`, `shiny_workforce_words.csv`, `shiny_sentiment.csv` |
| Presentation | `app-new.R` | Shiny-ready CSVs | Interactive dashboard |

## Validation & Observations
- Spot-checked CSV outputs for expected schema and row counts; Shiny app loads without runtime errors when dependencies are installed.
- Detected repeated comment entries in `comments.csv`, likely stemming from the source thread or limited deduplication; consider enhancing `distinct(comment_text)` in the scraping or EDA layers.
- Sentiment analysis uses unigrams and the `bing` lexicon—sufficient for polarity direction but may miss nuanced context (sarcasm, double negatives).
- API-driven job data is time-sensitive; reruns will overwrite CSVs with latest postings—version control recommended for longitudinal studies.

## Reproducibility Checklist
1. Place the McKinsey PDF (`the-economic-potential-of-generative-ai-the-next-productivity-frontier.pdf`) in the project root.
2. Install required R packages: `pdftools`, `tidytext`, `dplyr`, `httr2`, `jsonlite`, `stringr`, `ggplot2`, `shiny`, `shinydashboard`, `plotly`, `wordcloud2`, `DT`.
3. Update Reddit API credentials inside `scraper_for_socialmedia.R`.
4. Run the three acquisition scripts sequentially to refresh raw CSVs.
5. Execute `EDA.R` to regenerate aggregated Shiny datasets.
6. Launch `app-new.R` via `shiny::runApp()` to explore the dashboard.

## Recommendations & Next Steps
- **Data quality**: deduplicate Reddit comments and capture additional metadata (timestamp, score) for richer analysis.
- **Sentiment depth**: augment with contextual models (e.g., `tidytext` bigrams, `syuzhet`, or transformer-based classifiers) to validate the positive/negative split.
- **Job taxonomy**: enrich RemoteOK data with compensation, seniority, or skills by joining supplementary APIs or manual tagging.
- **Automation**: schedule scripts via `cron`/Task Scheduler and persist snapshots (e.g., dated CSV folders) for trend analysis.
- **Deployment**: host the Shiny app on shinyapps.io or Posit Connect and attach the published URL to satisfy the “Live Shiny URL” deliverable; bundle the narrative as a companion whitepaper.

