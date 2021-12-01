
# Calculate the percentage of jurisdictions where a majority of the racial group or household income level
# population lives in block groups targeted less than the median.
jur_demographic_majority_compared_to_prank_median <- function(bg_demo_prop_at_pred_rank, args, analysis_demo, departments) {
  race.labs <- list(
    title = "Race and Prediction",
    x = "Race",
    y = glue("Number of jurisdictions n = ({length(departments$client)})"),
    levels = c("White", "Asian", "Latino", "Black"),
    factor_names = c("white" = "White", "asian" = "Asian", "latino" = "Latino", "black" = "African American")
  )

  income.labs <- list(
    title = "Income and Prediction",
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

  is_prank_prop_gt_jur_total <-
    function(pop_est, demo, pop_buckets) {
      bg_demo_prop_at_pred_rank %>%
        mutate("{pop_buckets}_has_maj_{demo}_{pop_est}" :=
          if_else(.data[[glue("{demo}_{pop_est}_of_jur__{pop_buckets}")]] > .50,
            1, 0
          )) %>%
        select(department, contains("_has_maj_")) %>%
        summarise(
          n = n(),
          "{pop_buckets}_has_maj_{demo}_{pop_est}_sum" := sum(.data[[glue("{pop_buckets}_has_maj_{demo}_{pop_est}")]])
        )
    }
  plot.grey_box <- c(
    "Percent of jurisdictions where a majority of the group's\npopulation lives in block groups targeted\nless than the median.",
    "Percent of jurisdictions where a majority of the group's\npopulation lives in block groups targeted\nmore than the median."
  )
  names(plot.grey_box) <- c("lt_p50", "gt_p50")
  plot_data <- pmap(args, is_prank_prop_gt_jur_total) %>%
    reduce(inner_join, by = "n") %>%
    pivot_longer(contains("_has_maj_"),
      names_to = "demo_condition",
      values_to = "has_maj"
    ) %>%
    separate(demo_condition, c("pop_buckets", "race_est"), sep = "_has_maj_") %>%
    select(pop_buckets, race_est, has_maj) %>%
    separate(race_est, c("demo_val", "pop_est"), sep = "_") %>%
    group_by(demo_val, pop_buckets) %>%
    summarise(
      num_jur = min(has_maj),
      min_pop_est = paste(pop_est[which(has_maj == min(has_maj))], collapse = ", "),
      pct = num_jur / length(departments$client),
      plot_name = "prank_has_maj",
      total_num_jur = length(departments$client)
    ) %>%
    mutate(
      demo_val = plot.labs[[analysis_demo]][["factor_names"]][demo_val],
      demo_val = as_factor(demo_val),
      demo_val = fct_relevel(demo_val, levels = plot.labs[[analysis_demo]][["levels"]])
    )


  plot <- plot_data %>% ggplot(aes(x = demo_val, y = pct)) +
    geom_col(aes(fill = demo_val)) +
    scale_y_continuous() +
    geom_text(aes(label = jur_count_lab_format(num_jur)), nudge_y = -0.01, size = 3, color = "black") +
    facet_grid(. ~ pop_buckets, labeller = labeller(pop_buckets = plot.grey_box)) +
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


  ggsave(glue("out/plots/{analysis_demo}_prank_has_maj.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/{analysis_demo}_prank_has_maj.csv"))
  return(glue("out/dataframes/{analysis_demo}_prank_has_maj.csv"))
}
