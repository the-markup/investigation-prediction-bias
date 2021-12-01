
### Demographic composition (Income / Race) of deciles
demo_comp_comparison_all_pct_all_dept <- function(data, analysis_demo) {
  race.labs <- list(
    title = glue("Average Racial composition across all jurisdictions at different prediction percentiles"),
    x = "Block groups binned by prediction percentile score",
    y = "Proportion of race/ethnicity group in bin",
    levels = c("White", "Latino", "African American", "Asian"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American"),
    factor_num <- c("White" = 1, "Latino" = 2, "African American" = 3, "Asian" = 2)
  )

  income.labs <- list(
    title = glue("Average Household income composition across all jurisdictions at different prediction percentiles"),
    subtitle = "",
    x = "Block groups binned by prediction percentile score",
    y = "Proportion of household income group in bin",
    levels = c(
      "Less than 45k",
      "Between 75 and 100k",
      "Between 120 and 150k",
      "Greater than 200k"
    ),
    factor_names = c(
      "lt.45k" = "Less than 45k",
      "bw.75.100k" = "Between 75 and 100k",
      "bw.120.150k" = "Between 120 and 150k",
      "gt.200k" = "Greater than 200k"
    ),
    factor_num <- c("lt.45k" = 1, "bw.75.100k" = 2, "bw.120.150k" = 3, "gt.200k" = 4)
  )

  prank_labs <- c(
    "lt_p10" = "0 to 10th",
    "bw_p10_p20" = "10th to 20th",
    "bw_p20_p30" = "20th to 30th",
    "bw_p30_p40" = "30th to 40th",
    "bw_p40_p50" = "40th to 50th",
    "bw_p50_p60" = "50th to 60th",
    "bw_p60_p70" = "60th to 70th",
    "bw_p70_p80" = "70th to 80th",
    "bw_p80_p90" = "80th to 90th",
    "bw_p90_p100" = "90th to 100th"
  )


  plot.labs <- list(
    race = race.labs,
    income = income.labs
  )

  legend.labs <- list(
    race = "Race",
    income = "Household Income"
  )

  plot_data <- data %>%
    pivot_longer(
      contains("__"),
      names_to = "demo__prank",
      values_to = "values"
    ) %>%
    separate(demo__prank, c("demo", "prank_filter"), sep = "__") %>%
    separate(demo, c("demo", "pop_est"), sep = "_") %>%
    group_by(demo, prank_filter) %>%
    summarise(
      mean_val = mean(values)
    ) %>%
    mutate(
      prank_filter = prank_labs[prank_filter],
      prank_filter = fct_relevel(prank_filter, levels = prank_labs),
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]]),
    ) %>%
    mutate(
      demo_num = factor_num[demo]
    )


  plot <- plot_data %>% ggplot(aes(x = prank_filter, y = mean_val, fill = demo)) +
    geom_bar(position = "dodge", stat = "identity", alpha = 0.8) +
    geom_line(aes(group = demo_num, color = demo), show.legend = F, alpha = 1.0, linetype = "longdash") +
    scale_fill_discrete(name = legend.labs[[analysis_demo]]) +
    scale_y_continuous(labels = scales::percent) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      color = "Demographic Group"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(glue("out/plots/{analysis_demo}_demo_comp_mean_percentile.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_demo_comp_mean_percentile.csv"))
  return(glue("out/plots/{analysis_demo}_demo_comp_mean_percentile.png"))
}


### Demographic composition (Income / Race) of deciles per department
demo_comp_comparison_all_pct_per_dept <- function(data, analysis_demo) {
  race.labs <- list(
    title = glue("Racial composition at different prediction count percentiles"),
    x = "Block groups binned by prediction percentile score",
    y = "Proportion of race/ethnicity group in bin",
    levels = c("White", "Asian", "Latino", "African American"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American"),
    factor_num <- c("White" = 1, "Asian" = 2, "Latino" = 3, "African American" = 4)
  )

  income.labs <- list(
    title = glue("Household income composition at different prediction count percentiles"),
    subtitle = "",
    x = "Block groups binned by prediction percentile score",
    y = "Proportion of household income group in bin",
    levels = c(
      "Less than 45k",
      "Between 75 and 100k",
      "Between 120 and 150k",
      "Greater than 200k"
    ),
    factor_names = c(
      "lt.45k" = "Less than 45k",
      "bw.75.100k" = "Between 75 and 100k",
      "bw.120.150k" = "Between 120 and 150k",
      "gt.200k" = "Greater than 200k"
    ),
    factor_num <- c("lt.45k" = 4, "bw.75.100k" = 3, "bw.120.150k" = 2, "gt.200k" = 1)
  )
  prank_labs <- c(
    "lt_p10" = "0 to 10th",
    "bw_p10_p20" = "10th to 20th",
    "bw_p20_p30" = "20th to 30th",
    "bw_p30_p40" = "30th to 40th",
    "bw_p40_p50" = "40th to 50th",
    "bw_p50_p60" = "50th to 60th",
    "bw_p60_p70" = "60th to 70th",
    "bw_p70_p80" = "70th to 80th",
    "bw_p80_p90" = "80th to 90th",
    "bw_p90_p100" = "90th to 100th"
  )


  plot.labs <- list(
    race = race.labs,
    income = income.labs
  )

  legend.labs <- list(
    race = "Race",
    income = "Household Income"
  )

  plot_data <- data %>%
    pivot_longer(
      contains("__"),
      names_to = "demo__prank",
      values_to = "values"
    ) %>%
    separate(demo__prank, c("demo", "prank_filter"), sep = "__") %>%
    separate(demo, c("demo", "pop_est"), sep = "_") %>%
    mutate(
      prank_filter = prank_labs[prank_filter],
      prank_filter = fct_relevel(prank_filter, levels = prank_labs),
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]]),
    ) %>%
    mutate(
      demo_num = factor_num[demo]
    )


  plot <- plot_data %>% ggplot(aes(x = prank_filter, y = values, fill = demo)) +
    geom_line(aes(group = demo_num, color = demo), alpha = 1.0) +
    scale_y_continuous(labels = scales::percent) +
    facet_wrap(vars(client_name)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      color = legend.labs[[analysis_demo]]
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(glue("out/plots/{analysis_demo}_demo_comp_percentile.png"), plot, width = 15, height = 10)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_demo_comp_percentile.csv"))
  return(glue("out/dataframes/{analysis_demo}_demo_comp_percentile.csv"))
}
