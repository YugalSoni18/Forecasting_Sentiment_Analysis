#-------------------------------------------------------------------------------
## Installing Required Libraries
library(tidyverse)
library(tidytext)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(ggplot2)
library(scales)
library(tidyr)
library(stringi)
library(textclean)
library(topicmodels)  # Perform LDA Topic Modeling
library(textcat)
library(reshape2)
## Load the Dataset
hotel_reviews <- read.csv("data/HotelsData.csv")
set.seed(222)
sample_reviews <- sample_n(hotel_reviews, 2000)
colnames(sample_reviews) <- c("score", "text")
#-------------------------------------------------------------------------------
## Create a text corpus from sampled reviews
corpus <- VCorpus(VectorSource(sample_reviews$text))
# Clean the text: lowercase, remove accents, punctuation, numbers, stopwords
corpus_clean <- corpus %>%
  tm_map(content_transformer(tolower)) %>%                                          # Lowercase
  tm_map(content_transformer(function(x) stri_trans_general(x, "Latin-ASCII"))) %>%  # Handle accents
  tm_map(removePunctuation) %>%                                                     # Remove punctuation
  tm_map(removeNumbers) %>%                                                         # Remove numbers
  tm_map(removeWords, stopwords("en")) %>%                                          # Remove English stopwords
  tm_map(stripWhitespace) %>%                                                       # Remove extra whitespace
  tm_map(content_transformer(function(x) iconv(x, "latin1", "ASCII", sub="")))
# Update corpus
corpus <- corpus_clean
#-------------------------------------------------------------------------------
## Create a Document-Term Matrix (DTM)
dtm <- DocumentTermMatrix(corpus)
# Remove sparse terms and empty documents
dtm <- removeSparseTerms(dtm, 0.99)
#Check for number of empty rows 
num_empty_docs <- sum(rowSums(as.matrix(dtm)) == 0)
print(paste("Number of empty documents:", num_empty_docs))
#Remove empty rows by assigning values greater than 0 to the matrix
dtm <- dtm[rowSums(as.matrix(dtm)) > 0, ]
#-------------------------------------------------------------------------------
## Perform Latent Dirichlet Allocation (LDA) Topic Modeling
lda_model <- LDA(dtm, k = 5, control = list(seed = 222))
# Extract top terms for each topic
topics <- tidy(lda_model, matrix = "beta")    #Extract topics 
top_terms <- topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  arrange(topic, -beta)
# Visualize top terms using ggplot2
  mutate(term = reorder_within(term, beta, topic)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free_y") +
  coord_flip() +
  scale_x_reordered() +
  labs(title = "Top Terms in Each Topic", x = "Term", y = "Beta (P(term | topic))") +
  theme_minimal()
#-------------------------------------------------------------------------------
## Clean the Text and Tokenize
sample_reviews <- sample_reviews %>%
  mutate(text_id = row_number())
cleaned_words <- sample_reviews %>%
  mutate(text = replace_non_ascii(text)) %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  filter(!str_detect(word, "^[0-9]+$"),
# Join sentiment with tokenized words
cleaned_sentiments <- cleaned_words %>%
  inner_join(get_sentiments("bing"), by = "word")
# Aggregate sentiment score by review
review_sentiments <- cleaned_sentiments %>%
  count(text_id, sentiment) %>%
  pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) %>%
  mutate(overall_sentiment = case_when(
# Visualize Sentiment Distribution
# Use previously created 'review_sentiments' for plotting
ggplot(review_sentiments, aes(x = overall_sentiment, fill = overall_sentiment)) +
  geom_bar() +
  scale_fill_manual(values = c("Positive" = "blue", "Negative" = "red", "Neutral" = "gray")) +
  labs(title = "Sentiment Distribution Based on Text",
  theme_minimal(base_size = 14)
#-------------------------------------------------------------------------------
## Creating the Wordclouds to see the Comparison Between Common Words in Each Sentiment
cleaned_words <- cleaned_words %>%
  left_join(review_sentiments %>% select(text_id, overall_sentiment), by = "text_id")
positive_words <- cleaned_words %>%
  filter(overall_sentiment == "Positive") %>%
  count(word, sort = TRUE)
negative_words <- cleaned_words %>%
  filter(overall_sentiment == "Negative") %>%
  count(word, sort = TRUE)
# Visualising the Positive and Negative Wordcloud side-by-side
par(mfrow = c(1, 2))  
par(mar = c(1, 1, 3, 1))
wordcloud(words = positive_words$word, freq = positive_words$n, max.words = 100, scale = c(3, 0.8), colors = brewer.pal(8, "Dark2"))
title("Positive Reviews", col.main = "blue", font.main = 4)
wordcloud(words = negative_words$word, freq = negative_words$n, max.words = 100, scale = c(3, 0.8), colors = brewer.pal(8, "Reds"))
title("Negative Reviews", col.main = "red", font.main = 4)
#-------------------------------------------------------------------------------
## Checking Sentimental Contribution using Bing lexicon
bing <- get_sentiments("bing")
# Words with the Strongest Positive or Negative Sentiment Influence
sentiment_contributions <- cleaned_words %>% inner_join(bing, by = "word") %>%
  count(word, sentiment, sort = TRUE) %>% top_n(15, n)
# Visualising the Top Contributing Words (Positive & Negative) to Sentiments
ggplot(sentiment_contributions, aes(x = reorder(word, n), y = n, fill = sentiment)) + geom_col() +
  coord_flip() + scale_fill_manual(values = c("positive" = "blue", "negative" = "red")) +
  labs(title = "Top Contributing Words to Sentiment", x = "Word", y = "Contribution to Sentiment") +
  theme_minimal(base_size = 14)
#-------------------------------------------------------------------------------
## Using Bigram Analysis to check Most used two-words Phrases for Deeper Insight
bigrams <- sample_reviews %>% mutate(text = replace_non_ascii(text)) %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>% separate(bigram, into = c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word, !word2 %in% stop_words$word, !str_detect(word1, "^[0-9]+$"), !str_detect(word2, "^[0-9]+$")) %>%
  unite(bigram, word1, word2, sep = " ") %>% count(bigram, sort = TRUE) %>% top_n(15, n)
# Plotting Top 15 Frequent two-words Phrases
ggplot(bigrams, aes(x = reorder(bigram, n), y = n)) + geom_col(fill = "steelblue") +
  coord_flip() + labs(title = "Top 15 Frequent Phrases (Bigrams)", x = "Bigram", y = "Frequency") +
  theme_minimal(base_size = 14)
#-------------------------------------------------------------------------------
## Using Satisfaction Score Heatmap to show Words most Associated with High/Low Satisfaction Scores
word_scores <- sample_reviews %>% unnest_tokens(word, text) %>% anti_join(stop_words) %>%
  filter(!str_detect(word, "^[0-9]+$"), !word %in% c("hotel", "room", "rooms")) %>% group_by(word) %>%
  filter(n() > 15) %>%  # only keep words with enough frequency
  summarise(avg_score = mean(score), count = n()) %>% arrange(desc(avg_score)) %>% top_n(20, avg_score)
# Plotting Average Satisfaction Score by Frequent Words
ggplot(word_scores, aes(x = reorder(word, avg_score), y = avg_score, fill = avg_score)) +
  geom_col(show.legend = FALSE) + coord_flip() + scale_fill_gradient(low = "red", high = "blue") +
  labs(title = "Average Satisfaction Score by Frequent Word", x = "Word", y = "Average Review Score") +
  theme_minimal(base_size = 14)
#-------------------------------------------------------------------------------
