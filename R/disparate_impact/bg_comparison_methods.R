

# Calculate the average composition for all departments, of racial groups or household income levels
# in the different targeting groups based on predictions.
demo_comp_comparison_all_dept <- function(data, analysis_demo, departments) {
  plot.grey_box <- c(
    "Mean Composition of\nMost Targeted\nBlock Groups",
    "Mean Composition of\nMedian Targeted\nBlock Groups",
    "Mean Composition of\nLeast Targeted\nBlock Groups",
    "Mean Composition of\nJurisdiction Total"
  )
  names(plot.grey_box) <- c("in_max_tb", "in_med_tb", "in_min_tb", "total")

  race.labs <- list(
    title = glue(""),
    x = "Race",
    y = "Percentage Of Block Groups",
    levels = c("White", "Asian", "Latino", "African American"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American")
  )

  income.labs <- list(
    title = glue(""),
    subtitle = "",
    x = "Household Income",
    y = "Percentage Of Block Groups",
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
    group_by(department, demo, prank_filter) %>%
    summarise(
      min_value = min(values),
      min_pop_est = paste(pop_est[which(values == min(values))], collapse = ", "),
      plot_name = glue("{analysis_demo}_demo_comp_all")
    ) %>%
    group_by(demo, prank_filter) %>%
    summarise(
      mean_val = mean(min_value)
    ) %>%
    mutate(
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]]),
    )

  plot <- plot_data %>%
    ggplot(aes(x = demo, y = mean_val)) +
    geom_col(aes(fill = demo)) +
    scale_fill_discrete(name = legend.labs[[analysis_demo]]) +
    scale_y_continuous(labels = scales::percent) +
    geom_text(aes(label = scales::percent(round(mean_val, 2))), size = 3, nudge_y = -0.01, color = "black") +
    facet_grid(. ~ prank_filter, labeller = labeller(prank_filter = plot.grey_box)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      fill = plot.labs[[analysis_demo]]["x"]
    ) +
    theme(
      legend.position = "top",
      axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank()
    )

  ggsave(glue("out/plots/{analysis_demo}_demo_comp_all.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_demo_comp_all.csv"))
  return(glue("out/dataframes/{analysis_demo}_demo_comp_all.csv"))
}


# Calculate the average proportional increase, for all jurisdictions,
# in the targeting groups compared to jurisdiction the overall.
mean_demo_proportion_increase_at_prank <- function(bg_demo_prop_at_pred_rank, args, analysis_demo, departments) {
  plot.grey_box <- c(
    "Avg. Percent increase in population proportion for\n the most targeted block groups\ncompared to overall jurisdiction.",
    "Avg. Percent increase in population proportion for\n the median targeted block groups\ncompared to overall jurisdiction.",
    "Avg. Percent increase in population proportion for\n the least targeted block groups\ncompared to overall jurisdiction."
  )

  names(plot.grey_box) <- c("in_max_tb", "in_med_tb", "in_min_tb")

  race.labs <- list(
    title = "Predictions And Neighborhood Race",
    subtitle = "",
    x = "Race",
    y = "Pct increase in proportion",
    levels = c("White", "Asian", "Latino", "African American"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American")
  )

  income.labs <- list(
    title = "Predictions And Neighborhood Income",
    subtitle = "",
    x = "Household Income",
    y = "Pct increase in proportion",
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

  plot.labs <- list(
    race = race.labs,
    income = income.labs
  )

  mean_demo_inc_at_prank <- function(demo, pop_est, pop_buckets) {
    bg_demo_prop_at_pred_rank %>%
      mutate(
        "{pop_buckets}_pct_inc_{demo}_{pop_est}" :=
          (.data[[glue("{demo}_{pop_est}__{pop_buckets}")]] - .data[[glue("{demo}_{pop_est}__total")]]) / .data[[glue("{demo}_{pop_est}__total")]],
      ) %>%
      summarise(
        n = n(),
        "{pop_buckets}_pct_inc_{demo}_{pop_est}_sum" := mean(.data[[glue("{pop_buckets}_pct_inc_{demo}_{pop_est}")]])
      )
  }


  plot_data <- pmap(args %>% filter(pop_buckets != "total"), mean_demo_inc_at_prank) %>%
    reduce(inner_join, by = "n") %>%
    pivot_longer(
      contains("_pct_inc_"),
      names_to = "demo_condition",
      values_to = "pct_inc"
    ) %>%
    remove_missing() %>%
    separate(demo_condition, c("prank_filter", "demo_est"), sep = "_pct_inc_") %>%
    select(prank_filter, demo_est, pct_inc) %>%
    separate(demo_est, c("demo", "pop_est"), sep = "_") %>%
    group_by(demo, prank_filter) %>%
    summarise(
      pct_inc = pct_inc[which.min(abs(pct_inc))],
      min_pop_est = paste(pop_est[which.min(abs(pct_inc))], collapse = ", "),
      plot_name = glue("{analysis_demo}_inc_at_prank")
    ) %>%
    mutate(
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]])
    ) %>%
    mutate(
      prank_filter = as_factor(prank_filter),
      prank_filter = fct_relevel(prank_filter, "lt_p5", "gt_p95")
    )


  plot <- plot_data %>% ggplot(aes(x = demo, y = pct_inc)) +
    geom_col(aes(fill = demo)) +
    scale_y_continuous(labels = scales::percent) +
    geom_text(aes(label = scales::percent(pct_inc)), size = 3, nudge_y = -0.01, color = "black") +
    facet_grid(. ~ prank_filter, labeller = labeller(prank_filter = plot.grey_box)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      fill = plot.labs[[analysis_demo]]["x"]
    ) +
    theme(
      legend.position = "top",
      axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank()
    )

  ggsave(glue("out/plots/{analysis_demo}_inc_at_prank.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_inc_at_prank.csv"))
  return(glue("out/dataframes/{analysis_demo}_inc_at_prank.csv"))
}


# Compare the proportions of the different racial groups and household income levels
# compared to the jurisdiction overall.
demo_proportion_at_prank_compared_to_total <- function(bg_demo_prop_at_pred_rank, args, analysis_demo, departments) {
  plot.grey_box <- c(
    "Jurisdiction's where the proportion of each group living in\nthe most predicted blocks\nis higher than the city overall.",
    "Jurisdiction's where the proportion of each group living in\nthe median predicted blocks\nis higher than the city overall.",
    "Jurisdiction's where the proportion of each group living in\nthe least predicted blocks\nis higher than the city overall."
  )

  names(plot.grey_box) <- c("in_max_tb", "in_med_tb", "in_min_tb")

  race.labs <- list(
    title = "Racial composition of most, median and least targeted blocks",
    x = "Race",
    y = glue("Number of jurisdictions n = ({length(departments$client)})"),
    levels = c("White", "Asian", "Latino", "African American"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American")
  )

  income.labs <- list(
    title = "Household income composition of most, median and least targeted blocks",
    subtitle = "",
    x = "Household Income",
    y = glue("Number of jurisdictions n = ({length(departments$client)})"),
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

  plot.labs <- list(
    race = race.labs,
    income = income.labs
  )


  jur_count_lab_format <- function(num_jur) {
    str_c(scales::percent(round(num_jur / length(departments$client), 2)), " (", num_jur, ")", sep = "")
  }


  is_prank_prop_gt_jur_total <- function(pop_est, demo, pop_buckets) {
    bg_demo_prop_at_pred_rank %>%
      mutate(
        "{pop_buckets}_gt_total_{demo}_{pop_est}" :=
          if_else(.data[[glue("{demo}_{pop_est}__{pop_buckets}")]] > .data[[glue("{demo}_{pop_est}__total")]],
            1, 0
          )
      ) %>%
      select(department, contains("gt_total_")) %>%
      summarise(
        n = n(),
        "{pop_buckets}_gt_total_{demo}_{pop_est}_sum" := sum(.data[[glue("{pop_buckets}_gt_total_{demo}_{pop_est}")]])
      )
  }


  plot_data <- pmap(args %>% filter(pop_buckets != "total"), is_prank_prop_gt_jur_total) %>%
    reduce(inner_join, by = "n") %>%
    pivot_longer(
      contains("_gt_total_"),
      names_to = "demo_condition",
      values_to = "is_gt_total"
    ) %>%
    separate(demo_condition, c("prank_filter", "race_est"), sep = "_gt_total_") %>%
    select(prank_filter, race_est, is_gt_total) %>%
    separate(race_est, c("demo", "pop_est"), sep = "_") %>%
    group_by(demo, prank_filter) %>%
    summarise(
      num_jur = min(is_gt_total),
      min_pop_est = paste(pop_est[which(is_gt_total == min(is_gt_total))], collapse = ", "),
      pct = num_jur / length(departments$client),
      plot_name = "prank_gt_total"
    ) %>%
    mutate(
      demo = plot.labs[[analysis_demo]][["factor_names"]][demo],
      demo = as_factor(demo),
      demo = fct_relevel(demo, levels = plot.labs[[analysis_demo]][["levels"]])
    )


  plot <- plot_data %>% ggplot(aes(x = demo, y = pct)) +
    geom_col(aes(fill = demo)) +
    geom_text(aes(label = jur_count_lab_format(num_jur)), nudge_y = -0.01, size = 3, color = "black") +
    facet_grid(. ~ prank_filter, labeller = labeller(prank_filter = plot.grey_box)) +
    labs(
      title = plot.labs[[analysis_demo]][["title"]],
      subtitle = plot.labs[[analysis_demo]][["subtitle"]],
      x = plot.labs[[analysis_demo]]["x"],
      y = plot.labs[[analysis_demo]][["y"]],
      fill = plot.labs[[analysis_demo]]["x"]
    ) +
    theme(
      legend.position = "top",
      axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank()
    )


  ggsave(glue("out/plots/{analysis_demo}_at_prank_gt_total.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_at_prank_gt_total.csv"))
  return(glue("out/plots/{analysis_demo}_at_prank_gt_total.csv"))
}
