#loading required packages
  library(tidyverse)
  library("ggplot2")
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

# taking a look at what days have sales on them
tt = gg %>% 
  select(Date) %>%
  distinct() %>% 
  mutate(dof = weekdays(Date), 
         wk = (year(Date)*100+week(Date)), 
         counter = 1) %>% 
  select(dof, wk, counter) %>% 
  spread(dof, counter, sep = "_") %>% 
  filter(wk > 201501)
#how populated is each day?
round(apply(tt,2,function(x) sum(x,na.rm = T))/nrow(tt),2)


#Okay, defiantly kick out Saturday, that looks liek a flook, but we will need to fill in
#Monday, Tuesday, Wednesday, Thursday, and definatly Friday
# What's also intresting si that the law seems to have changed on 201636...


#There seem to be intresting sales with several typse of promotional products
left_join(gg,Item, by = 'Item.Number') %>% 
  group_by(Date, Item.Description) %>% 
  summarise(Sales = sum(Total.Sales)) %>% 
  ggplot(aes(x = Date, y = Sales, by = Item.Description)) + 
  geom_line(aes(col = Item.Description))

#Looking closer at the data

ss = ils %>%
  filter(Date >= as.Date('2015-08-31')) %>%
  mutate(Date = format(Date, '%Y%m') )  %>%
  group_by(Store.Number, Date) %>% 
  summarise(TotalSales = sum(Total.Sales)) %>%
  spread(Date, TotalSales, fill = 0 )

store_clust = hclust(dist(scale(ss)[,-1]), method = 'ward.D2') 




store_k = kmeans(scale(ss)[,-1], centers = 5)

k.max <- 15
ss_scaled = scale(ss)[,-1]
wss <- sapply(1:k.max, 
              function(k){kmeans(ss[,-1], k, nstart=50,iter.max = 15 )$tot.withinss})
wss
plot(1:k.max, wss,
     type="b", pch = 19, frame = FALSE, 
     xlab="Number of clusters K",
     ylab="Total within-clusters sum of squares")  


#creating a quick price to buy ratio
ptb <- ils %>%  group_by(Bottle_ML,BottleRetail,Category) %>% summarise(sold = sum(SoldAmount)/n())
hea


start_time = Sys.time()

for (i in Store_nbr){
  ttt = ils %>% filter_('Store.Number' == i)
  
}
Sys.time() - start_time

