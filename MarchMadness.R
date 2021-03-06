# Introduction  
## This project will be looking at College Basketball data from the 2014-2019 seasons. 
## The data was collected from the following location: https://www.kaggle.com/andrewsundberg/college-basketball-dataset#cbb19.csv. 
## The goal of this project will be to predict if a team will make it to the March Madness tournament, given the features provided. 
## In order to determine if a user will make it to the March Madness Tournament, we will need to perform so exploratory analysis to better understand the data. 
## We will predict based off a binary variable (1 = you made the March Madness Tournament and 0 = you did not)
## Given this is a binary variable, we will clean up the data and perform a logistic regression, decision tree and random forest to train the model. 
## To assess the model accuracy, we will review a ROC curve and confusion matrix to determine the overall accuracy of the model.

### Install Packages
install.packages('dplyr', repos = "http://cran.us.r-project.org")
install.packages('caret', repos = "http://cran.us.r-project.org")
install.packages('purrr', repos = "http://cran.us.r-project.org")
install.packages('tidyr', repos = "http://cran.us.r-project.org")
install.packages('ggplot2', repos = "http://cran.us.r-project.org")
install.packages('InformationValue', repos = "http://cran.us.r-project.org")

### Load necessary packages
library(dplyr)
library(caret)
library(purrr)
library(tidyr)
library(ggplot2)
library(InformationValue)
library(rpart)
library(randomForest)

# Data Import
### Import 5 years worth of datatsets
data1 <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb14.csv")
data1 <- subset(data1, select=-c(REC))
data2 <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb15.csv")
data2 <- subset(data2, select=-c(POSTSEASON))
data3 <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb16.csv")
data3 <- subset(data3, select=-c(POSTSEASON))
data4 <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb17.csv")
data4 <- subset(data4, select=-c(POSTSEASON))
data5 <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb18.csv")
data5 <- subset(data5, select=-c(POSTSEASON))
test_data <- read.csv("C:\\Users\\portesa\\Desktop\\Dataset\\cbb19.csv")
test_data <- subset(test_data, select=-c(POSTSEASON))

### Combine Data from 2014-2018 to serve as our training set
data <- union(data1,data2)
data <- union(data,data3)
data <- union(data, data4)
data <- union(data, data5)

## We have several columns of data. Let me first explain what is being stored in each column.
### TEAM = The Division 1 college basketball school
### CONF = The Athletic Conference in which the school participates in
### G = Number of Games played
### W = Number of games won 
### ADJOE = Adjusted Offensive Efficiency (An estimate of the offensive officiency (points scored per 100 possessions) a team has)
### ADJDE = Adjusted Defensive Efficiency (An estimate of the defensive efficiency (points allowed per 100 possessions) a team has)
### BARTHAG = Power Rating (Chance of beating an average D1 team)
### EFG_O = Effective Field Goal Percentage Shot
### EFG_D = Effective Field Goal Percentage Allowed
### TOR = Turnover Percentage Allowed (Turnover Rate)
### TORD = Turnover Percentage Committed (Steal Rate)
### ORB = Offensive Rebound Percentage
### DRB = Defensive Rebound Percentage 
### FTR = Free Throw Rate (How often the given team shoots Free Throws)
### FTRD = Free Throw Rate Allowed
### 2P_O = Two-Point Shooting Percentage
### 2P_D = Two-Point Shooting Percentage Allowed
### 3P_O = Three-Point Shooting Percentage
### 3P_D = Three-Point Shooting Percentage Allowed
### ADJ_T = Adjusted Tempo (An estimate of the temp (possessions per 40 minutes) a team would have against the team)
### WAB = Wins above Bubble (The bubble refers to the cut off between making the NCC March Madness Torunament and not)
### POSTSEASON = Round where the given team was eliminated or where their season ended
### Seed = Seed in the NCAA March Madness Tournament

head(data)

# Data Exploration/Data Visualization and Data Cleaning
## In this section we will be taking a look at the distributions of the different features. 
## This will help give us a better understanding of the data and what type of feature engineering we may want to do. 
## Before moving forward, we should check and address how we will deal with null values, convert any categorical variables to numerical values remove any unnecessary variables and produce some plots to better understand the distribution of the data in each column.

## First let's look at a summary of the data and check to see how many NA values are in the dataset by each variable
summary(data)
sapply(data, function(x) sum(is.na(x))) 

## View variable types to see which variables need to be converted to categorical
sapply(data,class)

## View how many conferences we have and then convert them to a numeric categorical variable
data <- data %>% mutate(CONF = toupper(CONF))
conference <- data %>% group_by(CONF) %>% summarize(ct = n())
conference <- conference %>% mutate(CONF_rating = as.numeric(factor(conference$CONF, levels = conference$CONF)))
data <- data %>% inner_join(conference)

## Same as above, but with the test_data
test_data <- test_data %>% mutate(CONF = toupper(CONF))
conference <- test_data %>% group_by(CONF) %>% summarize(ct = n())
conference <- conference %>% mutate(CONF_rating = as.numeric(factor(conference$CONF, levels = conference$CONF)))
test_data <- test_data %>% inner_join(conference)

## Plot a histogram of all the variables to see what the distribution
data %>% keep(is.numeric) %>% gather() %>% ggplot(aes(value)) + facet_wrap(~ key, scales = "free") + geom_histogram()

## Convert seed value to binary 1 or 0 response, so that we can have this as our categorical dependent variable.
data <- data %>% mutate(SEED = ifelse(data$SEED > 0,1, 0))

## Same as above, but with the test_data
test_data <- test_data %>% mutate(SEED = ifelse(test_data$SEED > 0,1, 0))

## Look at the distribution of the y_variable (if a team makes it to the NCAA March Madness Tournament)
data %>% group_by(SEED) %>% summarize(ct = n())

## Convert NA values in SEED column to 0
data[is.na(data)] <- 0 
data %>% group_by(SEED) %>% summarize(ct = n())

test_data[is.na(test_data)] <- 0 
test_data %>% group_by(SEED) %>% summarize(ct = n())

## Remove TEAM and CONF variable(s) from data set
data <- subset(data, select=-c(TEAM,CONF))
test_data <- subset(test_data, select=-c(TEAM,CONF))

## Look at correlation matrix of variables. Check for multicollinearity between features and little to no correlation with the SEED feature.
cor_matrix <- cor(data)
cor_matrix

# Analysis/Interpretation
## First I decided to look at all of the variables to see how many NA values were present.
## After further exploration, I was able to tell the the SEED and POSTSEASON columns were the only variables with NA present. 
## This is because if a team does not make the March Madness tournament, they are not given a postseason or seed value and is defaulted to NA.
## We view the class type of the data and convert the conference variable to a categorical variable. We then join this data to add the category of the conference and number of teams over the 4 year span in those conferences (non-distinct teams). 
## After plotting a histogram of all of the variables, I can conclude that all variables (except SEED, BARTHAG and CONF_rating) have a normal distribution.
## This could cause a potential issue later on because if we do not have a balanced data set in terms of a y variable, our model could be biased to predicting one value over another.
## I noticed that we had 1,132 rows of NA values in the SEED column. In order to make this a binary predictor, I converted all NA values to 0.
## Finally, we remove any unnecessary columns and run a correlation matrix to ensure all variables have a correlation with SEED greater than .1 or less than -.1.

## Split the data into 10% test set and 90% train set
### Seeing that the data set is not too large (as far as big data goes), we will have the largest possible train set to train the model.
set.seed(42)
test_index <- createDataPartition(y = data$SEED, times=1, p=0.1, list=FALSE)
test_set <- data[test_index,]
train_set <- data[-test_index,]

## K-fold Cross validation
cv_param <- trainControl(method="cv", number = 11)

# Model Building
## Logistic Regression
log_reg <- train(SEED~G+ADJOE+ADJDE+ct, data = train_set, method = 'glm')
summary(log_reg)
log_predictions <- predict(log_reg,test_set)
confusionMatrix(round(log_predictions,digits=0), test_set$SEED)
plotROC(test_set$SEED,log_predictions)

### Our logistic regression shows an Area under the curve score of .9253.

## Decision Tree
tree_ml <- train(SEED~., data = train_set, method = 'rpart', trControl = cv_param)
tree_predictions <- predict(tree_ml, test_set)
confusionMatrix(round(tree_predictions,digits=0), test_set$SEED)
plotROC(test_set$SEED,tree_predictions)

### Our decision tree shows an Area under the curve score of .7583. 

## Random Forest
set.seed(42)
rf_model <- randomForest(SEED~., data = train_set, boosting=TRUE, trControl = cv_param)
rf_predictions <- predict(rf_model, test_set)
confusionMatrix(round(rf_predictions,digits=0),test_set$SEED)
plotROC(test_set$SEED,rf_predictions)

### Our random forest shows an Area under the curve score of .935. 

# Results Using our Best Model
final_predictions <- predict(rf_model,test_data)
confusionMatrix(round(final_predictions,digits=0),test_data$SEED)
plotROC(test_data$SEED,final_predictions)

## We plot an ROC curve to see how much better our model is to someone randomly guessing. 
## An ROC Curve plots the True Positive rate (predicted 1 that were true 1's) over our False Positive Rate (predicted 1 that were true 0's). 
## Using our Random Forest model, we are able to predict which teams will make the NCAA March Madness Tournament with 96.35% accuracy. 
## It appears that the most significant variables in predicting whether a team will make the NCAA March Madness Tournament are Games, Adjusted Offensive Efficiency, Adjusted Defensive Efficiency and a count of the number of teams in each conference. 
## Other variables that showed statistical significance include BARTHAG and WAB, but had to be removed due to multicollinearity with the ADJOE feature. 
## We are also able to see that we had a 89.29% True Positive Rate and a 93.94% True Negative Rate. 
## Given the disproportinate number of teams that did not make the tournament, it makes sense that we are able to more accurately predict teams that do not make the tournmanent versus the teams that do.

# Conclusion
## Given that we had a training dataset of 1,750 teams over 5 years, we could have a slightly overfit model. 
## Even though this dataset accounts for roughly 55,000+ NCAA basketball games, more data would definitely help us better evaluate the strength of this model. 
## In conclusion, it appears that we did a great job cleaning up the dataset to predict whether or not a team will make the NCAA March Madness Tournament.
## It is currently limited because there are many other factors that could come into play as to why a team may make the NCAA March Madness Tournament. 
## Some of those factors include: winning conference championships, location of conference championships (the home team effect) and violations of NCAA rules.
## These limitations will mostly impact the lower seeds in the bracket as they do not have a guaranteed spot in the NCAA March Madness bracket.
## In the future, I could have looked into adding more data and incorporating additional factors that would have a high correlation to winning a conference championship, to better predict those lower seeds in the bracket.
