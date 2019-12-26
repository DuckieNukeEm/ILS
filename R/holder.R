#loading required packages
  library(tidyverse)
  library(ggplot2)
  library(lubridate)
#reading in data and doing last minute cleaninng
  w_dir = "~"
  ils = read.csv(paste(c(w_dir, "/R/Data/ILS/Reduced_Liquor_Sales.csv"), collapse = ""))
  Store = read.csv(paste(c(w_dir, "/R/Data/ILS/Liquor_Store.csv"), collapse = ""))
  Item = read.csv(paste(c(w_dir, "/R/Data/ILS/Liquor_Item.csv"), collapse = ""))
  Vendor = read.csv(paste(c(w_dir, "/R/Data/ILS/Liquor_Vendor.csv"), collapse = ""))
  Category = read.csv(paste(c(w_dir, "/R/Data/ILS/Liquor_Category.csv"), collapse = ""))
  ils = ils %>% mutate(Date = as.Date(Date))

# creating grey goose subset
  greygoose = Item %>% filter(grepl('Grey|grey|GREY', Item.Description)) %>% select(Item.Number)
  gg = ils %>% filter(Item.Number %in% (greygoose$Item.Number))

# creating sales by date
  gg %>%
    mutate(mnth = month(Date),
           wkday = weekdays(Date),
           wk = week(Date),
           yr = year(Date),
           yrmnth = yr*100 + mnth,
           yrweek = yr*100 + wk
           ) %>%
    filter(Item.Number %in% c(34433, 34422,34423,34425,34359)) %>%
    group_by(yr, mnth) %>%
    summarise( Sold = sum(Bottles.Sold)
          #       ,Sales = sum(Total.Sales)
          #       ,Profit = sum(Total.Sales - State.Bottle.Cost)
                ) %>%
    spread(mnth, Sold, sep = "Mnth")
  
  
  Dates_gg = 
        data_frame( Date = seq(as.Date('2012-01-02'), to = as.Date('2017-03-31'), by = "day")) %>%
        mutate(wkday = weekdays(Date),
               wk = week(Date),
               yr = year(Date))
              
  
  gg_agg_2 = gg %>% 
              filter(Item.Number == 34433) %>% 
              group_by(Date) %>% 
              summarise(Bottles.Sold = sum(Bottles.Sold),
                        Total.Sales = sum(Total.Sales)) %>%
              right_join( Dates_gg %>% filter(!(wkday %in% c('Saturday','Sunday'))),
                          by = 'Date') %>%
              mutate(Bottles.Sold = ifelse(is.na(Bottles.Sold), 0 ,Bottles.Sold ),
                     Total.Sales = ifelse(is.na(Total.Sales), 0, Total.Sales))
  