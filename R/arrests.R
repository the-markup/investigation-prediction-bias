
# Calculate correlation between arrest counts and predictions at the block level.
corr_arrests_predictions <- function(arrests_block_data) {
  arrests_block_data %>%
    mutate(
      had_predictions = if_else(predictions > 0, TRUE, FALSE),
      date = lubridate::as_date(day),
      block = as.factor(block)
    ) %>%
    mutate(
      week = lubridate::floor_date(date, unit = "week"),
    ) %>%
    group_by(client, block, week) %>%
    summarise(
      arrest_count_per_week = mean(arrests),
      pred_count_per_week = mean(predictions)
    ) %>%
    group_by(client) %>%
    summarise(
      corr = cor(arrest_count_per_week, pred_count_per_week, method = "kendall")
    )
}

# Calculate per-capita arrests data.
get_arrests_per_capita <- function(arrests, bg_ranked_pop_bounds) {
  most_targeted <- bg_ranked_pop_bounds %>%
    filter(in_max_tb == TRUE) %>%
    select(department, state, county, tract, block_group) %>%
    unique()

  least_targeted <- bg_ranked_pop_bounds %>%
    filter(in_min_tb == TRUE) %>%
    select(department, state, county, tract, block_group) %>%
    unique()

  arrest_counts <- arrests %>%
    filter(client != "indianapolis") %>%
    mutate(
      in_max_tb = if_else(
        client %in% most_targeted$department,
        state %in% most_targeted$state &
          county %in% most_targeted$county &
          tract %in% most_targeted$tract &
          block_group %in% most_targeted$block_group, TRUE, FALSE
      ),
      in_min_tb = if_else(
        client %in% least_targeted$department,
        state %in% least_targeted$state &
          county %in% least_targeted$county &
          tract %in% least_targeted$tract &
          block_group %in% least_targeted$block_group, TRUE, FALSE
      ),
    ) %>%
    group_by(client) %>%
    summarise(
      arrest_count = n(),
      arrest_max_tb = sum(if_else(in_max_tb == TRUE, 1, 0)),
      arrest_ltb = sum(if_else(in_min_tb == TRUE, 1, 0)),
    )
  pop_counts <- bg_ranked_pop_bounds %>%
    group_by(department) %>%
    summarise(
      pop = sum(total_race_est),
      pop_max_tb = sum(if_else(in_max_tb == TRUE, total_race_est, 0)),
      pop_not_max_tb = sum(if_else(in_max_tb == FALSE, total_race_est, 0)),
    )

  arrests_with_demo <- left_join(
    arrest_counts,
    pop_counts,
    c("client" = "department")
  )


  arrests_with_demo %>%
    mutate(
      arrest_max_tb_pc = arrest_max_tb / pop_max_tb,
      arrest_min_tb_pc = arrest_ltb / pop_not_max_tb,
      arrest_jur_total = arrest_count / pop
    )
}

# Calculate per-capita Use Of Force data.
get_uof_per_capita <- function(uof, bg_ranked_pop_bounds) {
  most_targeted <- bg_ranked_pop_bounds %>%
    filter(in_max_tb == TRUE) %>%
    select(department, state, county, tract, block_group) %>%
    unique()
  uof_counts <- uof %>%
    filter(client != "indianapolis") %>%
    mutate(
      in_max_tb = if_else(
        client %in% most_targeted$department,
        state %in% most_targeted$state &
          county %in% most_targeted$county &
          tract %in% most_targeted$tract &
          block_group %in% most_targeted$block_group, TRUE, FALSE
      ),
    ) %>%
    group_by(client) %>%
    summarise(
      uof_count = n(),
      uof_max_tb = sum(if_else(in_max_tb == TRUE, 1, 0)),
    )

  pop_counts <- bg_ranked_pop_bounds %>%
    group_by(department) %>%
    summarise(
      pop = sum(total_race_est),
      pop_max_tb = sum(if_else(in_max_tb == TRUE, total_race_est, 0)),
      pop_not_max_tb = sum(if_else(in_max_tb == FALSE, total_race_est, 0)),
    )

  uof_with_demo <- left_join(
    uof_counts,
    pop_counts,
    c("client" = "department")
  )

  uof_with_demo %>%
    mutate(
      uof_max_tb_pc = uof_max_tb / pop_max_tb,
      uof_jur_total_pc = uof_count / pop
    )
}

# Plot per-capita arrest data
plot_arrests_per_capita <- function(data) {
  arrest.labs <- list(
    title = "Arrests per capita",
    x = "Jurisdiction",
    y = "Per Capita Arrest Rate",
    levels = c("Most Targeted Blocks", "Jurisdiction Total", "Least Targeted Blocks"),
    factor_names = c(
      "arrest_max_tb_pc" = "Most Targeted Blocks",
      "arrest_min_tb_pc" = "Least Targeted Blocks",
      "arrest_jur_total" = "Jurisdiction Total"
    )
  )

  plot_data <- data %>%
    pivot_longer(arrest_max_tb_pc:arrest_jur_total,
      names_to = "name",
      values_to = "values"
    ) %>%
    mutate(
      name = arrest.labs[["factor_names"]][name],
      name = as_factor(name),
      name = fct_relevel(name, levels = arrest.labs[["levels"]]),
    )

  plot <- plot_data %>% ggplot(aes(x = client, y = values)) +
    geom_bar(aes(fill = name), stat = "identity", position = "dodge") +
    # geom_text(aes(label = round(values,2)),  size = 2, color = "black") +
    coord_cartesian(ylim = c(0, 1)) +
    theme(axis.text.x = element_text(angle = 45, margin = margin(t = 15))) +
    labs(
      title = arrest.labs[["title"]],
      subtitle = arrest.labs[["subtitle"]],
      x = arrest.labs["x"],
      y = arrest.labs[["y"]],
      fill = arrest.labs["x"]
    )
  ggsave("out/plots/arrests-per-capita.png", plot, width = 10, height = 7)
  plot_data %>% write_csv("out/dataframes/arrests-per-capita.csv")
  return("out/dataframes/arrests-per-capita.csv")
}


# Plot the correlation values for predictions and arrests.
plot_corr_arrest_preds <- function(corr_arrest_preds) {
  plot <- corr_arrest_preds %>%
    ggplot() +
    geom_bar(aes(x = client, y = corr), stat = "identity") +
    coord_cartesian(ylim = c(-1, 1)) +
    labs(title = "Correlation between arrests and predictions")

  ggsave("out/plots/corr-arrest-preds.png", plot, width = 10, height = 7)
  corr_arrest_preds %>% write_csv("out/dataframes/corr-arrest-preds.csv")
  return("out/plots/corr-arrest-preds.csv")
}
