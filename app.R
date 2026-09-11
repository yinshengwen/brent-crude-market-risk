# ============================================================
# Brent Crude Oil Trading & Market Risk Dashboard
# ============================================================
library(shiny)
library(shinydashboard)
library(tidyverse)
library(scales)
library(here)

# ------------------------------------------------------------
# 1. Load analysis results
# ------------------------------------------------------------

source(here("R/analysis2.R"))


# ============================================================
# 2. UI
# ============================================================

ui <- dashboardPage(
  
  dashboardHeader(
    title = "Brent Market Risk Dashboard"
  ),
  
  dashboardSidebar(
    
    sidebarMenu(
      
      menuItem(
        "Overview",
        tabName = "overview",
        icon = icon("chart-line")
      ),
      
      menuItem(
        "P&L Analysis",
        tabName = "pnl",
        icon = icon("dollar-sign")
      ),
      
      menuItem(
        "Risk Analysis",
        tabName = "risk",
        icon = icon("shield-halved")
      ),
      
      menuItem(
        "Machine Learning",
        tabName = "ml",
        icon = icon("robot")
      )
      
    )
  ),
  
  dashboardBody(
    
    # ========================================================
    # OVERVIEW
    # ========================================================
    
    tabItems(
      
      tabItem(
        
        tabName = "overview",
        
        fluidRow(
          
          valueBoxOutput(
            "current_brent",
            width = 3
          ),
          
          valueBoxOutput(
            "current_wti",
            width = 3
          ),
          
          valueBoxOutput(
            "position",
            width = 3
          ),
          
          valueBoxOutput(
            "latest_pnl",
            width = 3
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Brent Crude Oil Price",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotOutput("brent_price_plot",
                       height = "350px")
          ),
          
          box(
            title = "Brent-WTI Spread",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotOutput("spread_plot",
                       height = "350px")
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "60-Day Rolling Correlation",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            plotOutput("correlation_plot",
                       height = "300px")
          ),
          
          box(
            title = "EWMA Volatility",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            plotOutput("ewma_plot",
                       height = "300px")
          )
          
        )
        
      ),
      
      
      # ======================================================
      # P&L
      # ======================================================
      
      tabItem(
        
        tabName = "pnl",
        
        fluidRow(
          
          box(
            title = "Daily P&L",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            plotOutput(
              "daily_pnl_plot",
              height = "400px"
            )
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Cumulative P&L",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            plotOutput(
              "cumulative_pnl_plot",
              height = "400px"
            )
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Hedged vs Unhedged P&L",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            plotOutput(
              "hedged_pnl_plot",
              height = "400px"
            )
          )
          
        )
        
      ),
      
      
      # ======================================================
      # RISK
      # ======================================================
      
      tabItem(
        
        tabName = "risk",
        
        fluidRow(
          
          valueBoxOutput(
            "unhedged_var",
            width = 4
          ),
          
          valueBoxOutput(
            "hedged_var",
            width = 4
          ),
          
          valueBoxOutput(
            "var_reduction",
            width = 4
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Risk Summary",
            width = 12,
            status = "warning",
            solidHeader = TRUE,
            tableOutput("risk_table")
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Stress Testing",
            width = 12,
            status = "danger",
            solidHeader = TRUE,
            tableOutput("stress_table")
          )
          
        )
        
      ),
      
      
      # ======================================================
      # MACHINE LEARNING
      # ======================================================
      
      tabItem(
        
        tabName = "ml",
        
        fluidRow(
          
          box(
            title = "Model Comparison",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            tableOutput("ml_table")
          )
          
        ),
        
        fluidRow(
          
          box(
            title = "Random Forest Feature Importance",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            plotOutput(
              "importance_plot",
              height = "450px"
            )
          )
          
        )
        
      )
      
    )
  )
)


# ============================================================
# 3. SERVER
# ============================================================

server <- function(input, output, session) {
  
  
  # ==========================================================
  # OVERVIEW VALUE BOXES
  # ==========================================================
  
  output$current_brent <- renderValueBox({
    
    latest_brent <- tail(
      oil$brent[!is.na(oil$brent)],
      1
    )
    
    valueBox(
      value = paste0(
        "$",
        round(latest_brent, 2)
      ),
      subtitle = "Latest Brent Price",
      icon = icon("oil-well"),
      color = "blue"
    )
    
  })
  
  
  output$current_wti <- renderValueBox({
    
    latest_wti <- tail(
      oil$wti[!is.na(oil$wti)],
      1
    )
    
    valueBox(
      value = paste0(
        "$",
        round(latest_wti, 2)
      ),
      subtitle = "Latest WTI Price",
      icon = icon("droplet"),
      color = "aqua"
    )
    
  })
  
  
  output$position <- renderValueBox({
    
    valueBox(
      value = "100,000 bbl",
      subtitle = "Illustrative Brent Position",
      icon = icon("boxes-stacked"),
      color = "green"
    )
    
  })
  
  
  output$latest_pnl <- renderValueBox({
    
    latest_pnl <- tail(
      oil$brent_pnl[!is.na(oil$brent_pnl)],
      1
    )
    
    valueBox(
      value = dollar(latest_pnl),
      subtitle = "Latest Daily P&L",
      icon = icon("money-bill-trend-up"),
      color = "yellow"
    )
    
  })
  
  
  # ==========================================================
  # OVERVIEW PLOTS
  # ==========================================================
  
  output$brent_price_plot <- renderPlot({
    
    ggplot(
      oil,
      aes(
        x = date,
        y = brent
      )
    ) +
      
      geom_line() +
      
      labs(
        x = NULL,
        y = "USD / barrel"
      ) +
      
      theme_minimal()
    
  })
  
  
  output$spread_plot <- renderPlot({
    
    ggplot(
      oil,
      aes(
        x = date,
        y = brent_wti_spread
      )
    ) +
      
      geom_line() +
      
      geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      
      labs(
        x = NULL,
        y = "USD / barrel"
      ) +
      
      theme_minimal()
    
  })
  
  
  output$correlation_plot <- renderPlot({
    
    ggplot(
      oil,
      aes(
        x = date,
        y = rolling_corr
      )
    ) +
      
      geom_line() +
      
      geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      
      labs(
        x = NULL,
        y = "Correlation"
      ) +
      
      theme_minimal()
    
  })
  
  
  output$ewma_plot <- renderPlot({
    
    ggplot(
      ewma_data,
      aes(
        x = date,
        y = ewma_vol
      )
    ) +
      
      geom_line() +
      
      labs(
        x = NULL,
        y = "Volatility"
      ) +
      
      scale_y_continuous(
        labels = percent
      ) +
      
      theme_minimal()
    
  })
  
  
  # ==========================================================
  # P&L
  # ==========================================================
  
  output$daily_pnl_plot <- renderPlot({
    
    ggplot(
      oil %>%
        filter(!is.na(brent_pnl)),
      aes(
        x = date,
        y = brent_pnl
      )
    ) +
      
      geom_line() +
      
      geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      
      labs(
        x = NULL,
        y = "Daily P&L (USD)"
      ) +
      
      scale_y_continuous(
        labels = dollar
      ) +
      
      theme_minimal()
    
  })
  
  
  output$cumulative_pnl_plot <- renderPlot({
    
    ggplot(
      oil,
      aes(
        x = date,
        y = cumulative_pnl
      )
    ) +
      
      geom_line() +
      
      labs(
        x = NULL,
        y = "Cumulative P&L (USD)"
      ) +
      
      scale_y_continuous(
        labels = dollar
      ) +
      
      theme_minimal()
    
  })
  
  
  output$hedged_pnl_plot <- renderPlot({
    
    oil %>%
      
      select(
        date,
        brent_pnl,
        hedged_pnl
      ) %>%
      
      pivot_longer(
        cols = c(
          brent_pnl,
          hedged_pnl
        ),
        names_to = "Position",
        values_to = "P&L"
      ) %>%
      
      ggplot(
        aes(
          x = date,
          y = `P&L`,
          linetype = Position
        )
      ) +
      
      geom_line() +
      
      geom_hline(
        yintercept = 0,
        linetype = "dashed"
      ) +
      
      labs(
        x = NULL,
        y = "Daily P&L (USD)",
        linetype = NULL
      ) +
      
      scale_y_continuous(
        labels = dollar
      ) +
      
      theme_minimal()
    
  })
  
  
  # ==========================================================
  # RISK
  # ==========================================================
  
  output$unhedged_var <- renderValueBox({
    
    valueBox(
      value = dollar(VaR_95_unhedged),
      subtitle = "95% Historical VaR — Unhedged",
      icon = icon("triangle-exclamation"),
      color = "red"
    )
    
  })
  
  
  output$hedged_var <- renderValueBox({
    
    valueBox(
      value = dollar(VaR_95_hedged),
      subtitle = "95% Historical VaR — Hedged",
      icon = icon("shield"),
      color = "green"
    )
    
  })
  
  
  output$var_reduction <- renderValueBox({
    
    reduction <- 1 -
      abs(VaR_95_hedged) /
      abs(VaR_95_unhedged)
    
    valueBox(
      value = percent(reduction),
      subtitle = "VaR Reduction from Hedging",
      icon = icon("arrow-trend-down"),
      color = "blue"
    )
    
  })
  
  
  output$risk_table <- renderTable({
    
    risk_summary
    
  })
  
  
  output$stress_table <- renderTable({
    
    stress
    
  })
  
  
  # ==========================================================
  # MACHINE LEARNING
  # ==========================================================
  
  output$ml_table <- renderTable({
    
    ml_results
    
  })
  
  
  output$importance_plot <- renderPlot({
    
    ggplot(
      importance_df,
      aes(
        x = reorder(
          Feature,
          `%IncMSE`
        ),
        y = `%IncMSE`
      )
    ) +
      
      geom_col() +
      
      coord_flip() +
      
      labs(
        x = "Feature",
        y = "% Increase in MSE"
      ) +
      
      theme_minimal()
    
  })
  
}


# ============================================================
# 4. RUN APP
# ============================================================

shinyApp(
  ui = ui,
  server = server
)