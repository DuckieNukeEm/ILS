minmax = function(x, return_minmax = F){
  #convert the numeric variable x into a range of [-1,1]
  min_x = min(x)
  max_x = max(x)
  
  if(min_x == max_x) {stop("There is no variation of Data")}
  
  mm_x = 2*(x-min_x)/(max_x - min_x) - 1
  
  if (return_minmax){
   return(list( x= mm_x, min = min_x, max = max_x)) 
  }  else {return(mm_x)}
}

revert_minmax = function(x, min_x, max_x){
  #reverts from the min_max of [-1,1] to the original setup
  
  n_x = (x-1)*(max_x - min_x)/2 + min_x 
  
  return(n_x)
}

geocodeAddress <- function(address) {
  require(RJSONIO)
   url <- "http://maps.google.com/maps/api/geocode/json?address="
    url <- URLencode(paste(url, address, "&sensor=false", sep = ""))
    x <- fromJSON(url, simplify = FALSE)
    if (x$status == "OK") {
      out <- c(long = x$results[[1]]$geometry$location$lng,
               lat = x$results[[1]]$geometry$location$lat)
    } else {
      out <-  c(long = NA,
                lat = NA)
    }
    Sys.sleep(0.2)  # API only allows 5 requests per second
    return(out)
}


toproper = function(srng){
 srng =  gsub("(?<=\\b)([a-z])", "\\U\\1", tolower(srng), perl=TRUE)
 return(srng)
}


#### THe below function will take a time series and do the following
#### 1) decompose it and graph it
#### 2) calcluate 1 seasonal moving average of High and lows and graph it
#### 3) find the point where the mean shifts (using breakout)
#### 4) produce a prediciton on the trend using HW, Arima, and Prophit

show_me = function(x, #a univarte TS 
                   name, #name of the var - for the graph
                   window = "periodic", 
                   rolling_window = 0, 
                   CI = 0.95, #for plotting the error and moving average  bands
                   degree = 1, #breakout control
                   breakout_on = c("orig","diff"), #breakout control
                   beta = 0.001 #breakout contrl
                   ) {
  #checks:
  if(rolling_window ==0){rolling_window = frequency(x)}
  
  Z = qnorm(CI + (1-CI)/2)
  
  #first step, decompose the data into it's basic components
  x_stl = stl(x, s.window = window)
  decomp = data.frame(x_stl$time.series)
  x_df = data.frame( x = x,
                    seasonal = decomp$seasonal,
                    trend = decomp$trend,
                    remainder = decomp$remainder)
  #Creating the sd for error range, as well as the original ts  I'll use this when plotting
  x_df$sd_remainder = zoo::rollapply(x_df$remainder, width = rolling_window, FUN = sd, fill = 0, partial = T)
  
  x_df$CI_lower_remainder = x_df$trend  - x_df$sd_remainder * Z #getting the ci spread using Z score
  x_df$CI_upper_remainder = x_df$trend  + x_df$sd_remainder * Z
  
  x_df$sd_x = zoo::rollapply(x_df$x, width = rolling_window, FUN = sd, fill = 0, partial = T)
  
  x_df$CI_lower_x = x_df$trend  - x_df$sd_x * Z #getting the ci spread using Z score
  x_df$CI_upper_x = x_df$trend  + x_df$sd_x * Z
  
  #now getting points where the mean changes
  x_df$breakout = NA
  if(len(breakout_on) == 2 | breakout_on = 'orig'){
    x_breakout = BreakoutDetection::breakout(as.vector(x_df$x), min.size = freq/2, method = 'multi', beta = beta, degree = 1)  
    bo_loc_adj = 0
  } else{
    x_breakout = BreakoutDetection::breakout(diff(as.vector(x_df$x)), min.size = freq/2, method = 'multi', beta = beta, degree = 1)  
    bo_loc_adj = 1
  }
  
  x_df[x_breakout$loc + bo_loc_adj,"breakout"] = as.vector(time(x_df$x))[x_breakout$loc + bo_loc_adj]
  
  #creating confidnece interval for the actual value
  #now creating the error bar range
 info_plot =  ggplot(x_df, aes(x=as.vector(time(x)), y=trend)) +
              geom_line(show.legend = T) + #trend plot
              ylab(name) + 
              xlab('time') + 
              geom_line(aes(y = (trend + seasonal)),  col = 'black', alpha = 0.3 ) + #adding the seasonal over the trend
              geom_ribbon(aes(ymin=CI_lower_x, ymax=CI_upper_x), alpha=0.1, col = 'light blue', fill = 'light blue') + #Getting the 95% CI for the ts
              geom_ribbon(aes(ymin=CI_lower_remainder, ymax=CI_upper_remainder), alpha=0.1, fill = 'red',show.legend = T)   #error ribbon

 original_plot = ggplot(x_df, aes(x=as.vector(time(x)), y=as.vector(x))) +
                 geom_line(ylab = name) + #original plot
                 geom_vline(aes(xintercept =x_df$breakout), linetype = 'dashed', col = 'red', alpha = 0.4, na.rm = T)
 #info on cowplot:
 #https://cran.r-project.org/web/packages/cowplot/vignettes/plot_grid.html
cowplot::plot_grid(original_plot, info_plot, labels = c("Original", "Decomposed"),ncol = 1, align = 'v')
  
}






####usingt he below function to prep for a cv of alpha beta gamma for HoltWinters method
#### The purpose is so that I can train a HW model across mutliple ts without have it
#### overfit. 
hw_prep = function (x, 
                      alpha = NULL, 
                      beta = NULL, 
                      gamma = NULL, 
                      seasonal = c("additive","multiplicative"), 
                      start.periods = 2, 
                      l.start = NULL, 
                      b.start = NULL, 
                      s.start = NULL) {
  x <- as.ts(x)
  seasonal <- match.arg(seasonal)
  f <- frequency(x)
  if (!is.null(alpha) && (alpha == 0)) 
    stop("cannot fit models without level ('alpha' must not be 0 or FALSE)")
  if (!all(is.null(c(alpha, beta, gamma))) && any(c(alpha, 
                                                    beta, gamma) < 0 || c(alpha, beta, gamma) > 1)) 
    stop("'alpha', 'beta' and 'gamma' must be within the unit interval")
  if ((is.null(gamma) || gamma > 0)) {
    if (seasonal == "multiplicative" && any(x == 0)) 
      stop("data must be non-zero for multiplicative Holt-Winters")
    if (start.periods < 2) 
      stop("need at least 2 periods to compute seasonal start values")
  }
  if (!is.null(gamma) && is.logical(gamma) && !gamma) {
    expsmooth <- !is.null(beta) && is.logical(beta) && !beta
    if (is.null(l.start)) 
      l.start <- if (expsmooth) 
        x[1L]
    else x[2L]
    if (is.null(b.start)) 
      if (is.null(beta) || !is.logical(beta) || beta) 
        b.start <- x[2L] - x[1L]
      start.time <- 3 - expsmooth
      s.start <- 0
  }
  else {
    start.time <- f + 1
    wind <- start.periods * f
    st <- decompose(ts(x[1L:wind], start = start(x), frequency = f), 
                    seasonal)
    if (is.null(l.start) || is.null(b.start)) {
      dat <- na.omit(st$trend)
      cf <- coef(.lm.fit(x = cbind(1, seq_along(dat)), 
                         y = dat))
      if (is.null(l.start)) 
        l.start <- cf[1L]
      if (is.null(b.start)) 
        b.start <- cf[2L]
    }
    if (is.null(s.start)) 
      s.start <- st$figure
  }
  lenx <- as.integer(length(x))
  if (is.na(lenx)) 
    stop("invalid length(x)")
  len <- lenx - start.time + 1
  hw = function(alpha, beta, gamma)  .C(C_HoltWinters, 
                                        as.double(x), 
                                        as.integer(length(x)), 
                                        #STarting PAramaters
                                        as.double(max(min(alpha, 1), 0)), 
                                        as.double(max(min(beta,1), 0)), 
                                        as.double(max(min(gamma, 1), 0)), 
                                        as.integer(start.time), 
                                        #figuring otu which starting values to use
                                        as.integer(!+(seasonal == "multiplicative")), 
                                        as.integer(f), 
                                        as.integer(!is.logical(beta) || beta),
                                        as.integer(!is.logical(gamma) || gamma), 
                                        #Starting Values
                                        a = as.double(l.start), 
                                        b = as.double(b.start), 
                                        s = as.double(s.start), 
                                        #Return Values
                                        SSE = as.double(0), 
                                        level = double(len +1L), 
                                        trend = double(len + 1L), 
                                        seasonal = double(len +  f))                    

  
  return(list( 
              x = as.double(x),
              alpha = alpha,
              beta = beta,
              gamma = gamma,
              f = f,
              start.time = start.time,
              seasonal = seasonal,
              l.start = l.start,
              b.start = b.start,
              s.start = s.start,
              hw_fun = hw
               ))
}
  
  
  
  
  
  

