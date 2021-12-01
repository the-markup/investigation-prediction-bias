## Section - Analysis and Findings
## Correlation Prediction count and Race
corr_demo_predictions_race <- function(bg_ranked_pop_bounds, departments) {
  race.labs <- list(
    title = glue("Distribution of correlation coefficients for all {length(departments$client)} jurisdictions"),
    x = "Race",
    y = "Correlation Coeff.",
    levels = c("White", "Asian", "Latino", "African American"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American")
  )
  analysis_demo <- "race"

  plot.labs <- list(
    race = race.labs
  )

  plot_data <- bg_ranked_pop_bounds %>%
    group_by(department) %>%
    mutate(
      black_pct = black_est / total_race_est,
      latino_pct = latino_est / total_race_est,
      asian_pct = asian_est / total_race_est,
      white_pct = white_est / total_race_est
    ) %>%
    drop_na() %>%
    summarise(
      asian = cor(pred_pop_rank, asian_pct, method = "spearman"),
      black = cor(pred_pop_rank, black_pct, method = "spearman"),
      latino = cor(pred_pop_rank, latino_pct, method = "spearman"),
      white = cor(pred_pop_rank, white_pct, method = "spearman")
    ) %>%
    pivot_longer(
      asian:white,
      names_to = "demo",
      values_to = "value"
    ) %>%
    mutate(
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]]),
      plot_name = "race_corr_pred_count"
    )

  plot <- plot_data %>%
    ggplot() +
    geom_boxplot(aes(x = demo, y = value, fill = demo)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      fill = plot.labs[[analysis_demo]]["x"]
    )
  ggsave(glue("out/plots/race_corr_pred_count.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/race_corr_pred_count.csv"))
  return(glue("out/dataframes/race_corr_pred_count.csv"))
}


## Section - Analysis and Findings
## Correlation Prediction count and Household inome
corr_demo_predictions_income <- function(bg_ranked_pop_bounds, departments) {
  income.labs <- list(
    title = glue("Distribution of correlation coefficients for all {length(departments$client)} jurisdictions"),
    x = "Household Income",
    y = "Correlation Coeff.",
    levels = c(
      "Greater than 200k",
      "Between 120 and 150k",
      "Between 75 and 100k",
      "Less than 45k"
    ),
    factor_names = c(
      "lt.45k" = "Less than 45k",
      "bw.75.100k" = "Between 75 and 100k",
      "bw.120.150k" = "Between 120 and 150k",
      "gt.200k" = "Greater than 200k"
    )
  )
  analysis_demo <- "income"

  plot.labs <- list(
    income = income.labs
  )

  plot_data <- bg_ranked_pop_bounds %>%
    group_by(department) %>%
    mutate(
      lt.45k_pct = lt.45k_est / total_income_est,
      bw.75.100k_pct = bw.75.100k_est / total_income_est,
      bw.120.150k_pct = bw.120.150k_est / total_income_est,
      gt.200k_pct = gt.200k_est / total_income_est
    ) %>%
    drop_na() %>%
    summarise(
      lt.45k = cor(pred_pop_rank, lt.45k_pct, method = "spearman"),
      bw.75.100k = cor(pred_pop_rank, bw.75.100k_pct, method = "spearman"),
      bw.120.150k = cor(pred_pop_rank, bw.120.150k_pct, method = "spearman"),
      gt.200k = cor(pred_pop_rank, gt.200k_pct, method = "spearman")
    ) %>%
    pivot_longer(
      lt.45k:gt.200k,
      names_to = "demo",
      values_to = "value"
    ) %>%
    mutate(
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]]),
      plot_name = "income_corr_pred_count"
    )

  plot <- plot_data %>%
    ggplot() +
    geom_boxplot(aes(x = demo, y = value, fill = demo)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      fill = plot.labs[[analysis_demo]]["x"]
    )

  ggsave(glue("out/plots/income_corr_pred_count.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/income_corr_pred_count.csv"))
  return(glue("out/dataframes/income_corr_pred_count.csv"))
}
