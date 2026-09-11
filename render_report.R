# Render the portfolio report to HTML
# Run this file from the project root in RStudio.

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  install.packages("rmarkdown")
}

rmarkdown::render(
  "Brent_Crude_Market_Risk_Report.Rmd",
  output_file = "Brent_Crude_Market_Risk_Report.html",
  clean = TRUE
)
