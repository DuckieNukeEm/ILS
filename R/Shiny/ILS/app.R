#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)

source('~/git/Iowa-liquor-Sales/R/Shiny/ILS Shiny Functions.R')

w_dir = '~/R/Data/ILS/'
ils = load_ils(w_dir)  

desc_list = list(
Store = load_store(w_dir),
Item = load_item(w_dir),
Category = load_category(w_dir),
Vendor = load_vendor(w_dir)
)

start_up_flag = 0

#### Setting up some basic variabules for the input
input_var_list = list(
  years = ils %>% 
    select(YrWk) %>% 
    distinct() %>%  
    mutate(Yr = get_Yr(YrWk)) %>% 
    arrange(desc(Yr)) %>% 
    select(Yr) %>% 
    distinct() %>% 
    pull(Yr),
  min_date = ils %>% summarise(Date = min(Date)) %>% pull(Date),
  max_date = ils %>% summarise(Date = max(Date)) %>% pull(Date),
  store_vars = names(desc_list[['Store']])[2:7],
  item_vars = names(desc_list[['Item']][c(2,3,5,6,10)]),
  added_values = c('_Delta','_PercD','_MkShare','_MkShareD'),
  added_values_names =  c('Show Absolute Diffrence','Show Percentage Diffrence','Show Makret Share','Show Market Share Diffrence' )
  
)

names(input_var_list[['store_vars']]) = gsub('\\.',' ', input_var_list[['store_vars']])
names(input_var_list[['item_vars']]) = gsub('\\.',' ', input_var_list[['item_vars']])


start_up_flag = 1

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Iowa Liquor Data Set Explorations"),
   tags$head(   tags$style(HTML("hr {border-top: 1px solid #000000;}"))  ),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        conditionalPanel( 
          ###
          # main tab
          ###
              condition = "input.tabs == 'tab_1'",
              uiOutput('group_by_overview'),
              
              selectizeInput(inputId = "select_metric",
                             label = "Select Metrics to View in table",
                             choices = c( Sales = 'Sales',  Cost = 'Cost',`Bottles Sold` = 'Bottles.Sold'),
                             selected = 'Sales',
                             multiple = TRUE
                          ), #End SelectizeInput
              checkboxGroupInput(inputId = 'select_tab_Dis', 
                                 label = "Select what to show on Table",
                                 choiceNames = input_var_list[['added_values_names']],
                                 choiceValues = input_var_list[['added_values']],
                                 inline = FALSE)
          ) #End ConditionalPanel
       ,
       conditionalPanel( 
         ###
         # second tab
         ###
         condition = "input.tabs == 'tab_2'",
         uiOutput('group_by_performance'),
         
         radioButtons(inputId = "stl_metric",
                        label = "Select Metric to View",
                        choices = c( Sales = 'Sales',  Cost = 'Cost',`Bottles Sold` = 'Bottles.Sold'),
                        inline = FALSE), #End SelectizeInput
         radioButtons(inputId = 'stl_y', 
                            label = "Table View",
                            choices = c('Absolute view' = 'abs',
                                        'Relative growth starting from point in time'='rel'),
                            inline = FALSE), #End RadioButtons,
         selectizeInput(inputId = 'stl_x',
                      label = 'Line Type',
                      choices = c('Actual' = 'actual',
                                  'Trend' = 'trend',
                                  'Seasonal' = 'seasonal',
                                  'Remainder' = 'remainder'),
                      selected = 'tre',
                      multiple = FALSE) #end SelectizeInput
      
      ), #end condtionalPanel
           
      ###
      #
      # ADvance Filtering ----
      #
      ###
      hr(),
      actionButton(inputId = 'UpdateButton', 'Update Filter'),
      ###
      #   Store Filtering ----
      ###
        checkboxInput(inputId = 'show_store_filter1',
                      label = 'Filter by Store',
                      value = FALSE),  #End Store Filtering ind1
      
        conditionalPanel(
                condition = "input.show_store_filter1 == true",
                
                selectizeInput("store_filter1", 
                                "Select Store field", 
                                choices = input_var_list[['store_vars']],
                               multiple = FALSE), # end selectizeInput
                uiOutput("store1choice"),
                
                
                checkboxInput(inputId = 'show_store_filter2',
                            label = 'Filter by another Store aspect',
                            value = FALSE), #End Store Filtering 2
                conditionalPanel(
                      condition = "input.show_store_filter2 == true",
                      uiOutput('storefilter2eval'),
                      uiOutput('store2choice'),
                      
                      checkboxInput(inputId = 'show_store_filter3',
                                    label = 'Filter by a final Store aspect',
                                    value = FALSE), #End Store Filtering 3
                          conditionalPanel(
                            condition = "input.show_store_filter3 == true",
                            uiOutput('storefilter3eval'),
                            uiOutput('store3choice')
                          ) # end conditioanl store filter # 3
                )# end contitaion store filter # 2
          
        ), # end condtional store filtering by store
      
      ###
      #   Item Filtering ----
      ###  
      
        checkboxInput(inputId = 'show_item_filter1',
                        label = 'Filter by Item',
                        value = FALSE),  #End item Filtering ind1
          
          conditionalPanel(
            condition = "input.show_item_filter1 == true",
            
            selectizeInput("item_filter1", 
                           "Select Item field", 
                           choices = input_var_list[['item_vars']],
                           multiple = FALSE), # end selectizeInput
            uiOutput("item1choice"),
            
            
            checkboxInput(inputId = 'show_item_filter2',
                          label = 'Filter by another filter aspect',
                          value = FALSE), #End item Filtering 2
            conditionalPanel(
              condition = "input.show_item_filter2 == true",
              uiOutput('itemfilter2eval'),
              uiOutput('item2choice'),
              
              checkboxInput(inputId = 'show_item_filter3',
                            label = 'Filter by a final Store aspect',
                            value = FALSE), #End item filter ring 3
              conditionalPanel(
                condition = "input.show_item_filter3 == true",
                uiOutput('itemfilter3eval'),
                uiOutput('item3choice')
              ) # end conditioanl item filter # 3
            )# end contitaion item filter # 2
            
          ), # end condtional store filtering by store

        
  ###
  # other filtering ----
  ###
       hr(), 
       checkboxInput(inputId = 'Adv_overview', 
                          label = "Advance Controls",
                          value = FALSE), #End CheckboxGroupInput
      conditionalPanel(
        condition = "input.Adv_overview == true",
        dateInput(inputId = 'current_selected_date',
                  label = 'Select Refrence Date',
                  value = input_var_list[['max_date']],
                  min = input_var_list[['min_date']],
                  max = input_var_list[['max_date']]
        ), #End DateInput
        
        selectizeInput(inputId = "select_year",
                       label = "Select Years to consider",
                       choices = input_var_list[['years']],
                       selected = input_var_list[['years']][1:3],
                       multiple = TRUE
        ) #Enf SelectezeINput
      
      ) # end ConditionalPanel  
    ), #End SideBarPanel

   

 
      # Show a plot of the generated distribution
  mainPanel(
      tabsetPanel( type = 'tab',
                   id = 'tabs',
                   tabPanel("Overview",
                            value = 'tab_1',
                              DT::dataTableOutput("main_tbl"),
                            
                              plotOutput('main_plot')
               ), #end first TAb
                   tabPanel('Performance',
                            value = 'tab_2',
                            plotOutput('second_plot'),
                            DT::dataTableOutput("second_tbl")
                            
                            )
            
     
      
      ) # end tabsetPanel
   ) # end mainpanel
    
  
  ) # end SideBar
   
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
####
#
# # filtering functions ----
#
###
  
  ####
  # Group by
  ###
  
 group_by_choice = reactive({
    Chs = c(input_var_list[['item_vars']],input_var_list[['store_vars']])
    
    Sel = unique(c('Item.Description','Vendor.Name', 'Category.Name','Store.Name',
                   if(length(input$filter_store_sel1)) {input$store_filter1} else {NA},
                   if(length(input$filter_store_sel2)) {input$store_filter2} else {NA},
                   if(length(input$filter_store_sel3)) {input$store_filter3} else {NA},
                   if(length(input$item_store_sel1)) {input$item_filter1} else {NA},
                   if(length(input$item_store_sel2)) {input$item_filter2} else {NA},
                   if(length(input$item_store_sel3)) {input$item_filter3} else {NA}))
    Sel = Sel[!is.na(Sel)]
    
    Chs[sort(match(Sel,Chs))]
  })
  
 output$group_by_overview = renderUI({
   selectizeInput(inputId = 'select_group_by',
                      label = "Select Variables to group by in Table",
                     choices = group_by_choice(),
                      # choices = c(Item = 'Item.Description',
                      #             Vendor = "Vendor.Name",
                      #             Category = "Category.Name",
                      #             Store = "Store.Name"),
                      multiple = TRUE) #End CheckBoxGroupIntpu
 })
 output$group_by_performance = renderUI({
 selectizeInput(inputId = 'stl_group_by', 
                label = "Select Variables to group by in Table",
                choices = group_by_choice(),
                # choices = c('Group by Items' = 'Item.Description',
                #             'Group by Vendor' = 'Vendor.Name',
                #             'Group by Category' = 'Category.Number',
                #             'Group by Store' = 'Store.Number'),
                multiple = FALSE) #End CheckBoxGroupIntpu
 })
  
  ###
  # Store
  ###
  
  store_choice1 <- reactive({
    desc_list[['Store']] %>%  select_(input$store_filter1) %>% distinct() %>% arrange_(input$store_filter1)
  })
  
  # renders the picklist for the first selected filter
  output$store1choice <- renderUI(
    selectizeInput("filter_store_sel1", label = NA, choices = store_choice1(), multiple = TRUE)
  )
  
  #second Row
  output$storefilter2eval <- renderUI({
    store_Field = input_var_list[['store_vars']]
    selectInput("store_filter2", "Select another Store field", choices = store_Field[store_Field != input$store_filter1])
  })
  
  # vector of picklist values for the second selected filter
  store_choice2 <- reactive({
    desc_list[['Store']] %>%
        filter(eval(AndIN(input$store_filter1, input$filter_store_sel1))) %>% 
        select_(input$store_filter2) %>% 
        distinct() %>% 
        arrange_(input$store_filter2)
  })
  
  # renders picklist for filter 2
  output$store2choice <- renderUI(
    selectizeInput("filter_store_sel2", label = NA,  choices = store_choice2(), multiple = TRUE)
  )
  
# third column selected from remaining fieldsr=
  output$storefilter3eval <- renderUI({
    store_Field = input_var_list[['store_vars']]
    selectInput("store_filter3", "Select a final Store field", choices = sort(store_Field[!store_Field %in% c(input$store_filter1, input$store_filter2)]))
  })
  
  # vector of picklist values for third selected column
  store_choice3 <- reactive({
    desc_list[['Store']] %>%
      filter(eval(AndIN(input$store_filter1, input$filter_store_sel1, input$store_filter2, input$filter_store_sel2))) %>% 
      select_(input$store_filter3) %>% 
      distinct() %>% 
      arrange_(input$store_filter3)
  })
  
  # render picklist for filter 3
  output$store3choice <- renderUI(
    selectizeInput("filter_store_sel3", label = NA, choices = store_choice3(), multiple = TRUE)
  )  
  
  
  ###
  # Item
  ###
  
  #
  item_choice1 <- reactive({
    desc_list[['Item']] %>%  select_(input$item_filter1) %>% distinct() %>% arrange_(input$item_filter1)
  })
  
  # renders the picklist for the first selected filter
  output$item1choice <- renderUI(
    selectizeInput("filter_item_sel1", label = NA, "Select Item condition:", choices = item_choice1(), multiple = TRUE)
  )
  
  
  #second Row
  output$itemfilter2eval <- renderUI({
    item_Field = input_var_list[['item_vars']]
    selectInput("item_filter2", "Select another item field", choices = item_Field[item_Field != input$item_filter1])
  })
  
  # vector of picklist values for the second selected filter
  item_choice2 <- reactive({
    desc_list[['Item']] %>%
      filter(eval(AndIN(input$item_filter1, input$filter_item_sel1))) %>% 
      select_(input$item_filter2) %>% 
      distinct() %>% 
      arrange_(input$item_filter2)
  })
  
  # renders picklist for filter 2
  output$item2choice <- renderUI(
    selectizeInput("filter_item_sel2", label = NA,  choices = item_choice2(), multiple = TRUE)
  )
  
  
  # third column selected from remaining fieldsr=
  output$itemfilter3eval <- renderUI({
    item_Field = input_var_list[['item_vars']]
    selectInput("item_filter3", "Select a final Item field", choices = sort(item_Field[!item_Field %in% c(input$item_filter1, input$item_filter2)]))
  })
  
  # vector of picklist values for third selected column
  item_choice3 <- reactive({
    desc_list[['Item']] %>%
      filter(eval(AndIN(input$item_filter1, 
                        input$filter_item_sel1, 
                        input$item_filter2, 
                        input$filter_item_sel2))) %>% 
      select_(input$item_filter3) %>% 
      distinct() %>% 
      arrange_(input$item_filter3)
  })
  
  # render picklist for filter 3
  output$item3choice <- renderUI(
    selectizeInput("filter_item_sel3", label = NA, choices = item_choice3(), multiple = TRUE)
  )  
  
####
#
# creating reactive functions ----
#
####

#  ils_1_year_filter = reactive({
#      setDT(ils)[get_Yr(YrWk) %in% input$select_year]  
#  })
 
  
  store_reactive = reactive({
    start_up_flag = 1
    desc_list[['Store']] %>%
      filter(eval(AndIN(input$store_filter1, 
                        input$filter_store_sel1,
                        input$store_filter2,
                        input$filter_store_sel2,
                        input$store_filter3, 
                        input$filter_store_sel3
                        ))) %>%
      group_by(Store.Number) %>% 
      arrange(desc(End_dt), desc(Start_dt)) %>% 
      filter(row_number() == 1) %>%
      select_('Store.Number', 
              'Store.Name',
              input$store_filter1,
              input$store_filter2,
              input$store_filter3)
  })
  
  
  item_reactive = reactive({
    desc_list[['Item']] %>%
      filter(eval(AndIN(input$item_filter1, 
                        input$filter_item_sel1,
                        input$item_filter2, 
                        input$filter_item_sel2,
                        input$item_filter3, 
                        input$filter_item_sel3
      ))) %>%
      group_by(Item.Number) %>% 
      arrange(desc(End_dt), desc(Start_dt)) %>% 
      filter(row_number() == 1) %>%
      ungroup() %>%
      select_('Item.Number', 
              'Item.Description',
              'Vendor.Name',
              'Category.Name',
              input$item_filter1,
              input$item_filter2,
              input$item_filter3) 
  }) 
  
  
  # ils_1_year_filter = eventReactive(input$UpdateButton, {
  #   setDT(ils, key = c('Item.Number','Store.Number'))[get_Yr(YrWk) %in% input$select_year]  %>%
  #   {
  #     if(length(input$filter_store_sel1) > 0) {
  #       inner_join( (.),
  #         store_reactive(),
  #         by = 'Store_Nbr'
  #       )
  #     } else { (.) }
  #   } 
  # })
  
  ils_year_filter = reactive({
    setDT(ils)[ get_Yr(YrWk) %in% input$select_year] #%>%
    #  filter(Vendor.Number == 260)
  })
  
  #ils_si_filter = eventReactive(paste0(start_up_flag,input$UpdateButton), {
  
  ils_si_filter = reactive({
    input$UpdateButton
    isolate({
    setDT(
              setDT(ils_year_filter(), 
                   key ='Item.Number')[setDT(item_reactive(), key = c('Item.Number')), nomatch = 0],
              
                  key = 'Store.Number')[setDT(store_reactive(), key = 'Store.Number'),  nomatch = 0]
    })
  })
  
   
#  ils_2_group_by = reactive({
#    ils_1_year_filter() %>%
#    {if(length(input$select_group_by) >= 1) (group_by_at(.,.vars = input$select_group_by)) else (.)}   
#  })

  ils_3_agg_to_wk = reactive({
    #ils_2_group_by() %>%
    ils_si_filter() %>%
    {if(length(input$select_group_by) >= 1) (group_by_at(.,.vars = input$select_group_by)) else (.)}   %>%
      agg_to_wk()
  })
  
  ils_4_YoY = reactive({
    ils_3_agg_to_wk() %>% 
   #{if(length(input$select_group_by) >= 1) (add_detail(.,desc_list, input$select_group_by, F)) else (.)} %>%
   #{if(length(input$select_group_by) >= 1)  (group_by_at(., .vars = CHF_var_num2name(input$select_group_by))) else (.)} %>%
      YoY_n(Cur_Date = input$current_selected_date, metric = input$select_metric) 
  })
  
   output$main_tbl = DT::renderDataTable({

    ils_4_YoY() %>%
        {
           if(!'_Delta' %in% input$select_tab_Dis ) {
             select((.), -ends_with('_Delta'))
           } else (.)
        } %>% {
          if(!'_PercD' %in% input$select_tab_Dis ) {
            select((.), -ends_with('_PercD'))
          } else (.)
        }  %>% {
          if(!'_MkShare' %in% input$select_tab_Dis ) {
            select((.), -ends_with('_MkShare'))
          } else (.)
        } %>% {
          if(!'_MkShareD' %in% input$select_tab_Dis ) {
            select((.), -ends_with('_MkShareD'))
          } else (.)
        } %>%
       proper_format()  %>%
       proper_names()
     #ils_4_YoY() %>% head() 
   })

   output$main_plot = renderPlot({

      ils_3_agg_to_wk() %>%
   #   {if(length(input$select_group_by) >= 1) (add_detail(.,desc_list, input$select_group_by, F)) else (.)} %>%
       mutate(Wk = get_Wk(YrWk),
              Yr = get_Yr(YrWk)
              )  %>%
        group_by_at(.vars = c('Wk','Yr')) %>%
        summarise_at(.vars = input$select_metric, .funs = sum, na.rm = T) %>%
        gather_(key_col = 'Metric', value_col = 'Value', gather_cols = input$select_metric  ) %>%
        ggplot(aes(x = Wk, y = Value, col = factor(Yr) )) +
          geom_line() +
          facet_wrap(~Metric, scales = 'free') +
          scale_y_continuous(labels = scales::comma)

   })

   
   
   
   std_group_by_1 = reactive({
     ils_1_year_filter() %>%
     {if(length(input$stl_group_by) >= 1) (group_by_at(.,.vars = input$stl_group_by)) else (.)} %>%
       agg_to_wk()
   })
   
   std_group_by_2 = reactive({
     ils_si_filter() %>%
     {if(length(input$stl_group_by) >= 1) (group_by_at(.,.vars = input$stl_group_by)) else (.)} %>%
    agg_to_wk() %>%
       group_level_stl( metric = input$stl_metric)
   })
   
   output$second_plot = renderPlot({
        g_title = if(input$stl_y == 'rel'){
                          paste0('Relative ', input$stl_group_by, ' of ', input$stl_metric, ' by ', input$stl_group_by )
                  } else {
                    paste0(input$stl_group_by, ' of ', input$stl_metric, ' by ', input$stl_group_by )
                  }
        y_title =  input$stl_metric
    
       gg_out =  
            std_group_by_2() %>%
           mutate(YRWKDT = last_day_of_week(YrWk)) %>%
        #   {if(length(input$stl_group_by) >= 1) (group_by_at(.,.vars = input$stl_group_by)) else (.)} %>%
           {if(input$stl_y == 'rel') {normalize_stl(.)} else (.) } %>%
           mutate_(y = input$stl_x,
                   Grouping = input$stl_group_by) 
           #mutate_(.dots = setNames(mut_method, 'grouping')) %>%
       
        gplot = gg_out %>%
           ggplot(aes(x = YRWKDT, y =  y,  col = factor(Grouping))) + 
           geom_line() + 
           ggtitle(g_title) +
           labs(x = 'Date',
                y = y_title)
        
        if(nrow(gg_out %>% select(1) %>% distinct()) > 10){
          gplot = gplot + theme(legend.position="none")
          
        }
         
        gplot
     
   })
   
   output$second_tbl = DT::renderDataTable({
     std_group_by_2() %>%
             mutate(Date = last_day_of_week(YrWk)) %>%
     #        {if(length(input$stl_group_by) >= 1) (group_by_at(.,.vars = input$stl_group_by)) else (.)} %>%
             {if(input$stl_y == 'rel') {normalize_stl(.)} else (.) } %>%
             mutate_(y = input$stl_x,
                     Grouping = input$stl_group_by) 
          
   })
   
}

# Run the application 
shinyApp(ui = ui, server = server)

