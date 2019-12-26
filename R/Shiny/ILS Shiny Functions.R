########################################################################################################################
###                                                                                                                  ###
###          Function to help with the Shiny App for ILS. God I hope this works :P                                   ###
###                                                                                                                  ###
########################################################################################################################


####
#
# Loading packages ----
#
####

library(tidyverse)
library(data.table)
library(lubridate)
library(forecast)

###
#
# Constant holder functions ----
#
###
CHF_var_num2name = function(Indx = NA){
  

 ret_v = c(Vendor.Number = 'Vendor.Name',
    Category.Number = 'Category.Name',
    Store.Number = 'Store.Name',
    Item.Number = 'Item.Description')
 
 if(sum(!is.na(Indx)) > 0) {
  # ret_v =ret_v[match(Indx, names(ret_v))]
   ret_v =as.vector(ret_v[Indx])
 }
 
  return(ret_v)
}

CHF_var_name2num = function(Indx){

  ret_v = c(Vendor.Name = 'Vendor.Number',
            Category.Name = 'Category.Number',
            Store.Name = 'Store.Number',
            Item.Description = 'Item.Number')
  
  if(sum(!is.na(Indx)) > 0) {
   # ret_v =ret_v[match(Indx, names(ret_v))]
    ret_v =as.vector(ret_v[Indx])
  }
  
  return(ret_v)

}



###
#
# Loading files function ----
#
###

w_dir = '~/R/Data/ILS/'
load_ils = function(w_dir){
  ils = fread(paste(c(w_dir, "Reduced_Liquor_Sales.csv"), collapse = "")) %>%
    mutate(Vendor.Number2 = as.numeric(as.character(Vendor.Number))) %>%
    select(-Vendor.Number2) %>%
    rename(Vendor.Number = Vendor.Number)
  return(ils)
}

load_store = function(w_dir){
  Store = read_csv(paste(c(w_dir, "Liquor_Store.csv"), collapse = ""))
  return(Store)
}

load_item = function(w_dir){
  Item = read_csv(paste(c(w_dir, "Liquor_Item.csv"), collapse = "")) %>%
    mutate(Vendor.Number2 = as.numeric(as.character(Vendor.Number))) %>%
    select(-Vendor.Number2) %>%
    rename(Vendor.Number = Vendor.Number)
  return(Item)
}

load_vendor = function(w_dir){
  Vendor = read_csv(paste(c(w_dir, "Liquor_Vendor.csv"), collapse = "")) %>%
    mutate(Vendor.Number2 = as.numeric(as.character(Vendor.Number))) %>%
    select(-Vendor.Number2) %>%
    rename(Vendor.Number = Vendor.Number)
  return(Vendor)
}

load_category = function(w_dir){
  Category = read_csv(paste(c(w_dir, "Liquor_Category.csv"), collapse = ""))
  return(Category)
}

#####
#
# Defensive Checking ----
#
#####

has_var = function(df, var_name){
  names_df = names(df)
  
  if(var_name %in% names_df){
    return(TRUE)
  } else {
    return(FALSE)
  }
  
}


####
#
# spread function that can spread through more than one columns ----
#
###


spread_n = function(df = (.), key, value, ...) {
  # https://community.rstudio.com/t/spread-with-multiple-value-columns/5378
  # quote key
  keyq <- rlang::enquo(key)
  # break value vector into quotes
  valueq <- rlang::enquo(value)
  s <- rlang::quos(!!valueq)
  df %>% gather(variable, value, !!!s) %>%
    unite(temp, !!keyq, variable) %>%
    spread(temp, value, ...)
}


####
#
# Date Functions ----
#
###

  #converts to YrWk
convert_to_YrWk = function(Dt){
  Dt = year(Dt) * 100  + week(Dt)
  return(Dt)
}

  #Gets the Year from a YrWk formate
get_Yr = function(YrWk){
  Yr = (YrWk %/% 100)
  return(Yr)
}

  #Gets the Week form a YrWk Formate
get_Wk = function(YrWk){
  Wk = (YrWk %% 100)
  return(Wk)
}

  #returns the last of the Week from the YrWk Format
last_day_of_week = function(YrWk = NA, Dt = NA){
  if(is.na(YrWk) && is.na(Dt)){
    stop('Need a Date or YearWeek')
  } 
  
  if (is.na(YrWk) && !is.na(Dt)) {
    YrWk = convert_to_YrWk(Dt)
  } 
    pulled_Wk = get_Wk(YrWk)
    pulled_Yr = get_Yr(YrWk)

  lst_dy = ymd(pulled_Yr*10000 + 101) + (7 * pulled_Wk) - 1
  #adjusting for the fact that 52*7 = 364, one day shy of a full year
  lst_dy[pulled_Wk == 53] = ymd(pulled_Yr[pulled_Wk == 53]*10000 + 1231)
  
  return(lst_dy)
}



####
#
# Yr, Mnth, Week adjustmend function (add or subtrack any of the following and it will figure out the next ones)
#
###

date_adj = function(Dy = 0, Wk = 0, Mnth = 0, Yr = 0){
  #Note, this default to going form week to year, not week, month then year
  adj_vector = c('Day' = Dy,'Week' = Wk, 'Month' =  Mnth, 'Year' = Yr)

  # Day Adjustment
    adj_vector['Week'] = adj_vector['Week'] + sign(adj_vector['Day']) * (abs(adj_vector['Day']) %/% 7)
    adj_vector['Day'] =  sign(adj_vector['Day']) * (abs(adj_vector['Day']) %% 7)
  # Week Adjustment
    if(Mnth != 0){
      adj_vector['Month'] = adj_vector['Month'] +  sign(adj_vector['Week']) * (abs(adj_vector['Week']) %/% 4)
      adj_vector['Week'] =  sign(adj_vector['Week']) * (abs(adj_vector['Week']) %% 4)
    # Month Adjustment
      adj_vector['Year'] =  adj_vector['Year'] +  sign(adj_vector['Month']) * (abs(adj_vector['Month']) %/% 12)
      adj_vector['Month'] = sign(adj_vector['Month']) * (abs(adj_vector['Month']) %% 12)
    } else {
    
    adj_vector['Year'] =  adj_vector['Year'] +  sign(adj_vector['Week']) * (abs(adj_vector['Week']) %/% 52)
    adj_vector['Week'] = sign(adj_vector['Week']) * (abs(adj_vector['Week']) %% 52)
    
      }
return(adj_vector)
}


YMWD_shift = function(Dt, D_chng = NA, W_chng = NA, M_chng = NA, Y_chng = NA){
  if(!is.Date(Dt)){
    Dt = try(as.Date(Dt), silent = T)
    if(inherits(Dt, 'tryerror')){
      stop('Need a date for DT, didnt get a date foo')
    }
  }
  
  if(!is.na(D_chng)) {
    Dt = seq(Dt, length = 2, by = paste(D_chng, 'day'))[2]
  }
  
  if(!is.na(W_chng)){
    Dt = seq(Dt, length = 2, by = paste(W_chng, 'week'))[2]
  }
  
  if(!is.na(M_chng)){
    Dt = seq(Dt, length = 2, by = paste(M_chng, 'month'))[2]
  }
  
  if(!is.na(Y_chng)){
    Dt = seq(Dt, length = 2, by = paste(Y_chng, 'year'))[2]
  }
  
  return(Dt)
}

####
#
# Aggregate down to wk ----
#
###

agg_to_wk = function(df = (.)){
  the_OG_group_by = group_vars(df)
  the_group_by = the_OG_group_by
  if(!('YrWk' %in% the_group_by)) { the_group_by =  c(the_group_by,'YrWk') }
    setDT(df)[,
        .(
          Start_Date = min(Date),
          End_Date = max(Date),
          Bottles.Sold = sum(Bottles.Sold),
          Cost = sum(Cost),
          Sales = sum(Sales),
          Record_Count = .N
        ) ,
        by = the_group_by
      ] %>%
    group_by_at(.vars = the_OG_group_by)
} 



####
#
# YoY Functions ----
#
###

YoY_n = function(df = (.), 
                 Cur_Date, 
                 Yoy_wk_Shift = -52,
                 metric = c('Cost', 'Sales','Bottles.Sold'), 
                 remove_dates = T,
                 YTD = T,
                 calc_abs_change = T, 
                 calc_per_change = T,
                 calc_market_share = T,
                 calc_market_share_change = T) {
  # REMEBER [1] is Current [2] is the LAG
  
  ###
  # Need to put the metric in alphabetic order, that's how the spread will do it
  ###
  metric = metric[order(metric)]
  
  ###
  # Finding the correct Dates to use
  ###
  adjust_YW = date_adj(0, Yoy_wk_Shift, 0, 0)
  Date_selector = c(last_day_of_week(Dt = Cur_Date), 
                    last_day_of_week(Dt = YMWD_shift(Cur_Date, W_chng = adjust_YW['Week'], Y_chng = adjust_YW['Year']))
                  )
  
  Date_selector = convert_to_YrWk(Date_selector)
  Date_names = c('Cur',paste0('L_',abs(Yoy_wk_Shift), sep = ""))
  ###
  # settin gup a delta V, if we have a flag to remove the date fields
  ###
  delta_v = setdiff(names(df),c('Wk','Yr','Date','Start_Date','End_Date'))
  
  ###
  # Setting up the sammrise after the spread
  ###
  
  sum_method = c(paste("sum(",paste(Date_names[1], metric, sep = "_"),")", sep = ""),
                 paste("sum(",paste(Date_names[2], metric, sep = "_"),")", sep = "")
  )
  sum_names = c(paste(Date_names[1], metric, sep = "_"),
              paste(Date_names[2], metric, sep = "_"))
  
  ###
  # Doing through and doing the spread so that we have a Cur column and a lag column
  ###
  if(YTD){
    Date_sel_start = (get_Yr(Date_selector)*100)+1 #Finding the start of the Year
    
    df =
    setDT(  #cool little data table trick to speed up processing
    {if(remove_dates) {df[,delta_v]} else {df} } %>%
      ungroup() 
      )[YrWk %in% c(Date_sel_start[1]:Date_selector[1], Date_sel_start[2]:Date_selector[2])
        ] %>% 
      distinct() %>%
    #  filter(YrWk %in% Date_sel_start[1]:Date_selector[1] | YrWk %in% Date_sel_start[2]:Date_selector[2]) %>%
      mutate(Lag_level = ifelse(YrWk >= Date_sel_start[1], Date_names[1], Date_names[2] )) %>%
      spread_n(Lag_level, metric, fill = 0) %>%
      mutate(YrWk = Date_selector[1]) %>%
      group_by_at(.vars = group_vars(df)) %>%
      summarise_(.dots = setNames(sum_method, sum_names)) 
    
    
  } else {
    df =
    {if(remove_dates) {df[,delta_v]} else {df} } %>%
      filter(YrWk %in% Date_selector) %>%
      mutate(Lag_level = ifelse(YrWk == Date_selector[1], Date_names[1], Date_names[2] ),
      YrWk = Date_selector[1]) %>%
      #  { if(remove_dates)  select(.,rlang::quos(delta_y)) else . }  %>%
      spread_n(Lag_level, metric, fill = 0) %>%
      group_by_at(.vars = group_vars(df)) %>%
      summarise_(.dots = setNames(sum_method, sum_names)) 
  }
  
  ###
  # Doing calculations to get an ABs delta or a relative delta, depending
  # This is a little trick, as we gotta make sure it works properly
  # but we don't know what metrics will be invovled :/
  # using the following site as a guide
  # https://datascience.blog.wzb.eu/2016/09/27/dynamic-columnvariable-names-with-dplyr-using-standard-evaluation-functions/
  ###
  
  if(calc_abs_change){
  #Calcuing the names for Abs change
    mut_method =
      paste(paste(Date_names[1], metric, sep = "_"), #IE Cur_Cost
            paste(Date_names[2], metric, sep = "_"),  #IE L52_Cost
            sep = "-" )  # to makes Cur_Cost - L52_Cost
    
    mut_names = paste(metric, "Delta",sep = "_")
  
    df = df %>%
      mutate_(.dots = setNames(mut_method, mut_names))
  }
    
  if(calc_per_change){
      #if(calc_abs_change) { 
      #Calcuing the names for per change
      #for()
    mut_method = 
      paste(paste(
              paste(Date_names[1], metric, sep = "_"), #IE Cur_Cost
              paste(Date_names[2], metric, sep = "_"), #IE L52_Cost
                    sep = "/" ),  # To make Cur_Cost/L52_Cost
            '1', 
            sep = " - ") # to finally make (Cur_Cost / L52_Cost - 1)
      
    mut_names = paste(metric, "PercD",sep = "_")
      
    df = df %>%
        mutate_(.dots = setNames(mut_method, mut_names))
  }
  
  if(calc_market_share){
    mut_method_cur =
      paste(Date_names[1], '_', metric, '/sum(' ,Date_names[1], '_',  metric, ', na.rm = T)', sep = "")
    
      # paste(paste(Date_names[1], metric, sep = "_"), #IE Cur_Cost
      #       paste(
      #           c('sum(',
      #           paste(Date_names[1], metric, sep = "_"),  #IE CurCost
      #           ', na.rm = T)'),
      #           sep = "", collapse = ""), #IE sum( Cur_Cost, na.rm = T)
      #       sep = "/" )  # to makes Cur_Cost/sum(Cur_cist, na.rm = T)
    
    mut_method_lag =
      paste(Date_names[2], '_', metric, '/sum(' ,Date_names[2], '_',  metric, ', na.rm = T)', sep = "")
      # paste(paste(Date_names[2], metric, sep = "_"), #IE L52_Cost
      #       paste(
      #         c('sum(',
      #           paste(Date_names[2], metric, sep = "_"),  #IE 52Cost
      #           ', na.rm = T)'),
      #         sep = "", collapse = ""), #IE sum( L52_Cost, na.rm = T)
      #       sep = "/" )  # to makes L52_Cost/sum(L52_cist, na.rm = T)
    
    mut_names_cur = paste(Date_names[1], metric, "MkShare",sep = "_")
    mut_names_lag = paste(Date_names[2], metric, "MkShare",sep = "_")
    
    df = df %>%
      mutate_(.dots = setNames(mut_method_cur, mut_names_cur)) %>% 
      mutate_(.dots = setNames(mut_method_lag, mut_names_lag)) 
  }
  
  if(calc_market_share_change){
    #if(calc_abs_change) { 
    #Calcuing the names for per change
    #for()
    mut_method = 
      paste(
        paste(Date_names[1], metric, 'MkShare', sep = "_"), #IE Cur_Cost_MkShare
        paste(Date_names[2], metric, 'MkShare', sep = "_"), #IE L52_Cost_MkShare
        sep = " - ") # to finally make Cur_Cost_MkShare - L52_Cost_MkShare
    
    mut_names = paste(metric, "MkShareD",sep = "_")
    
    df = df %>%
      mutate_(.dots = setNames(mut_method, mut_names))
  }
  
  return(df)
}



#####
#
# A series of functions that will take an Item and all stores and find the following:
# Total Sales (or what evermetric), Trend, Seasonal, and Error
#
#####

stl_wrapper = function(var_of_int, YrWk, freq = 52){
  NWO = order(YrWk)
  var_of_int = var_of_int[NWO]
  YrWk = YrWk[NWO]
  #Would like to add a functionality for seasonal items :D
  ts_s = try(ts(var_of_int, frequency = freq), silent = TRUE)
  if(!inherits(ts_s,'try-error')) {
    val = try(stl(ts_s, s.window = 'per'), silent = TRUE)  
  }
  
  if(inherits(val,'try-error') | inherits(ts_s,'try-error') ){
    val = data.frame(YrWk, 
                     actual = var_of_int, 
                     seasonal = 0, 
                     trend = 0, 
                     remainder = 0, 
                     error = 1, stringsAsFactors = FALSE)
  } else {
  val = data.frame(YrWk,
                   actual = var_of_int,
                   val$time.series, 
                   error = 0, stringsAsFactors = FALSE)
  }
  return(val)
}

group_level_stl = function(df = (.), metric = 'Sales'){
  # takes the first grouping of DF and then performs stl on it
  # returns a tibble with var name, YrWK, seasonal, trend, remainder, and error_ind
  
  
  if(!has_var(df, 'YrWk') & !has_var(df, 'Wk') & !has_var(df, 'Yr')){
    df = df %>% agg_to_wk() %>% group_by_at(.vars=group_vars(df))
  }
  if(length(group_vars(df)) > 1 ){
    df = df %>% group_by_at(.vars = group_vars(df)[1]) %>% agg_to_wk()
  }
  
  groupings = group_vars(df)
  df = setDT(df)[, stl_wrapper(get(metric), YrWk ), by = groupings ] %>%
        group_by_at(.vars = groupings)
  
  return(df)
 # Create a matrix that holds stores by full range of index
  
 # figure out methodologies to populate matrix
  
 # Fill in 
  
}

normalize_stl = function(df = (.), refrence_date = NULL, remove_errors = TRUE){
  # Takes the output from stl_wrapper or group_level_stl
  # and normailzies it to a refrence point (Defaults to the minimum date of the data frame)
  # Based on the group_by that comes in
  # currenly it's written for a specifica data frame, working on genearlizing it

 df = 
   df %>%
      arrange(YrWk) %>%
     {if(remove_errors) {filter((.), error == 0) } else (.)} %>% 
     mutate_at(3:6, funs(./first(.)))
   
 return(df)
    
}
####
#
# prettyfy functions ----
#
####
  
add_detail = function(df = (.), desc_list, vars_to_add, keep_number = T){
  ###
  # replaces the numbers with a character description of the file
  # will remove number in the group by if need be :P
  #
  ###
  group_holder = group_vars(df)
  if(length(group_holder) > 0){
    if(any(vars_to_add %in% group_holder)) {
      group_holder = c(group_holder, CHF_var_num2name(vars_to_add))
    }
    if(!keep_number){
      group_holder = setdiff(group_holder, vars_to_add)
    }
  } 
 
df %>%
  ungroup() %>% #maeks the joining eaiser
  {
    if('Item.Number' %in% vars_to_add) {
      inner_join((.),
                 desc_list[['Item']] %>% 
                   select(-Category.Number, 
                          -Category.Name,
                          -Vendor.Number,
                          -Vendor.Name) %>%
                   group_by(Item.Number) %>% 
                   arrange(desc(End_dt), desc(Start_dt)) %>% 
                   filter(row_number() == 1) %>%
                   ungroup(),
                 by = 'Item.Number') 
    } else (.)
  } %>%
  {
    if('Vendor.Number' %in% vars_to_add & !('Item.Number' %in% vars_to_add)) {
      inner_join((.),
                 desc_list[['Vendor']] %>% 
                   group_by(Vendor.Number) %>% 
                   arrange(Vendor.Number) %>% 
                   filter(row_number() == 1) %>%
                    ungroup(),
                 by = 'Vendor.Number') 
    } else (.)
  } %>%
  {
    if('Category.Number' %in% vars_to_add & !('Item.Number' %in% vars_to_add)) {
      inner_join((.),
                 desc_list[['Category']] %>% 
                   group_by(Category.Number) %>% 
                   arrange(Category.Number) %>% 
                   filter(row_number() == 1) %>%
                   ungroup(),
                 by = 'Category.Number') 
    } else (.)
  } %>%
  {
    if('Store.Number' %in% vars_to_add) {
      inner_join((.),
                 desc_list[['Store']] %>% 
                   group_by(Store.Number) %>% 
                   arrange(desc(End_dt), desc(Start_dt)) %>% 
                   filter(row_number() == 1) %>%
                   ungroup(),
                 by = 'Store.Number') 
    } else (.)
  }  %>%  
#  {if(!keep_number) (select(., !ends_with(".Number") )) else (.) }
  {if(!keep_number) (select((.),-one_of(vars_to_add))) else (.) } %>%
  {if(length(group_holder)>0) {group_by_at(.tbl = (.), .vars = group_holder)} else (.)}

}


format_per = function(x, round = T){
  x = x * 100
  if(round){
    x = round(x, 2)
  }
  
  x = paste0(x, " %")
}

format_comma = function(x){
  x = gsub("(?!^)(?=(?:\\d{3})+$)", ",", round(x), perl=T)
  return(x)
}

format_dollar = function(x){
  x = paste("$ ", x, sep = "")
  
}

proper_format = function(df = (.), 
                         do_prct = T, 
                         Perc_Search_Pattern = c('PercD','MkShareD','MkShare'),
                         do_comma = T, 
                         Comma_Search_Pattern = c('Bottles.Sold','Sales','Cost', 'Delta'),
                         do_dollar = T, 
                         Dollar_Search_Pattern = c('Sales','Cost'))  {
  ###
  # formats the data so percets have a '12.3%'
  # dollars add a dollars sigh '$ 12.35'
  #add a 1000 comma seporators '12,322,532'
  # round to nearest major unit '$ 12.54M' ,'$ 16.99K' I may make it so it levels them all in the same units
  ###
  group_holder = group_vars(df)
  df_names = names(df)
  
  Perc_loc = grepl(paste(Perc_Search_Pattern, sep = "", collapse = "|"), names(df))
  
  Comma_loc = grepl(paste(Comma_Search_Pattern, sep = "", collapse = "|"), df_names) & !Perc_loc
  
  Dollar_loc = grepl(paste(Dollar_Search_Pattern, sep = "", collapse = "|"), df_names) & !Perc_loc
  
   df %>%
  {
    if(do_prct) {
    mutate_at((.), .vars = df_names[Perc_loc], .funs = format_per)
  } else (.)
  } %>%
  {
    if(do_comma) {
      mutate_at((.), .vars = df_names[Comma_loc], .funs = format_comma)
    } else (.)
  } %>%
  {
    if(do_dollar) {
      mutate_at((.), .vars = df_names[Dollar_loc], .funs = format_dollar)
    } else (.)
  } 
    
    
}


proper_names = function(df = (.), YTD = T){
  #converts names such as L_52 to YoY, and Delta = Diff and PerD = % Diff, wish I could get a dleta to pring
  df_names = names(df)
  
  #replacing Descriptors
  df_names = sub('\\.', ' ', df_names)
  
  #Lets take care of the easy names first, like PercD and Delta
  df_names = sub('_PercD', ' % Diffrence',df_names)
  df_names = sub('_Delta', ' Diffrence', df_names)
  df_names = sub('_MkShareD', ' MarketShare Diffrence', df_names)
  df_names = sub('_MkShare', ' MarketShare', df_names)
  
  #Replacing Cur_
  if(YTD) {
    df_names = sub('Cur_', 'Current YTD ', df_names)
  } else {
    df_names = sub('Cur_', 'Current ', df_names)
  }
  #now...the hard part, taking care of the lags!
    #first getting ride of the L_
    df_names = sub('L_','',df_names)
  
    #FIguring out hwere the numbers are
     num_loc = grepl("([0-9]+).*$", df_names)
     num_names = df_names[num_loc]
     #num_num = as.numeric(gsub("([0-9]+).*$", "\\1", num_names))
    #Now running it through to do the math
     
    #  num_num =
    #   sapply(num_num, FUN = function(x){ 
    #    ret_t =
    #     if(!is.numeric(x)){
    #      '0 Wks Ago '
    #    } else if(x == 52 ) {
    #      '1 Yr Ago'
    #    } else if(x > 52 & x < 104) {
    #       paste(c('1 Yr and', x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
    #     } else if(x > 52)  {
    #      paste(c( x %/% 52, 'Yrs and', x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
    #     } else {
    #       paste(c( x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
    #     }
    #    return(ret_t)
    #  }
    #  )
    # if(YTD) {num_num = paste(num_num,'YTD')}
    #  
    #Now inserting them back into the names
     for(nn in seq_along(num_names)){
       x = as.numeric(gsub("([0-9]+).*$", "\\1", num_names[nn]))
      # print(x)
       x = 
        if(!is.numeric(x)){
         '0 Wks Ago '
       } else if(x == 52 ) {
         '1 Yr Ago'
       } else if(x > 52 & x < 104) {
         paste(c('1 Yr and', x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
       } else if(x > 52)  {
         paste(c( x %/% 52, 'Yrs and', x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
       } else {
         paste(c( x %% 52, 'Wks Ago' ), sep = "", collapse = " ")
       }
       
       if(YTD) {x = paste(x,'YTD')}
       x = paste(x, ' ', sep = "", collapse = "") 
      # num_names[nn] = sub('(\\d*_)*', x ,num_names[nn])
       num_names[nn] = str_replace(num_names[nn],'(\\d*_)*', x )
       #print(num_names[nn])
     }
     
    df_names[num_loc] = num_names
       
       
  names(df) = df_names
  
  df
}



####
#
# filter_functions (jeez lueze, )
#
###


AndIN = function(...){
  #takes a bunch of conditiosn and cranks out a string that data.table can evaluate 
  #https://stackoverflow.com/questions/28129791/no-such-index-at-level-1-syntax-error-in-simple-word-locator-function
  #https://stackoverflow.com/questions/34970312/create-a-filter-expression-i-dynamically-in-data-table
  #
  x = list(...)
  
  if(length(x) == 0) {return(TRUE)}
  
  
  cond = list()
  for(i in 1:floor(length(x)/2)){
  
    if(length(x[[2*i - 1]]) == 0 | length(x[[2*i]]) == 0) {next}
    
    if(is.na(x[[2*i - 1]])) {next}
    
    cond[[ unlist(x[[2*i - 1]]) ]] = x[[ 2 * i]]
  }
  
  if(length(cond) == 0) {return(TRUE)}
  
  
cond =   Reduce(
  function(x, y) call("&", call("(",x), call("(",y)),
  lapply(names(cond), function(var) call("%in%", as.name(var), cond[[var]]))
)  
  
 return(cond)
  
}

####
#
# Useful Sites to consider
#
###

#https://www.r-bloggers.com/writing-pipe-friendly-functions/
#https://community.rstudio.com/t/spread-with-multiple-value-columns/5378
#Dyplr
  #https://dplyr.tidyverse.org/articles/programming.html
  #Data.table
  #https://rstudio-pubs-static.s3.amazonaws.com/219545_47274c811c464f1ca1f07959b8243688.html#overview-1

#puling from the census beauro
# https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress?address=3709+West+Cherokee+Rd%2C+Rogers%2C+AR+72758&benchmark=Public_AR_Current&vintage=ACS2017_Current&layers=all&format=json


#### Red, White and Berry is Item Number  77956, 77994



