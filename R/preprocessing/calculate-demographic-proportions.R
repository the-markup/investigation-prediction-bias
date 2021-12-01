# Calculate the demographic proportions of block groups at the different targeting levels based on predictions.
get_demo_proportions <- function(data, pop_type, demo, pop_est, pop_buckets, demo_type) {
  if (pop_type == "bg") {
    if (pop_buckets == "total") {
      data %>%
        group_by(department) %>%
        summarise(
          "{demo}_{pop_est}__{pop_buckets}" :=
            sum(.data[[glue("{demo}_{pop_est}")]]) /
              sum(.data[[glue("total_{demo_type}_{pop_est}")]])
        ) %>%
        replace(is.na(.), 0)
    } else {
      t <- data %>%
        group_by(department) %>%
        summarise(
          "{demo}_{pop_est}__{pop_buckets}" :=
            sum(if_else(.data[[as.character(pop_buckets)]] == TRUE, .data[[glue("{demo}_{pop_est}")]], 0)) /
              sum(if_else(.data[[as.character(pop_buckets)]] == TRUE, .data[[glue("total_{demo_type}_{pop_est}")]], 0))
        ) %>%
        replace(is.na(.), 0)
    }
  } else {
    t <- data %>%
      group_by(department) %>%
      summarise(
        "{demo}_{pop_est}_of_jur__{pop_buckets}" :=
          sum(ifelse(.data[[as.character(pop_buckets)]] == TRUE, .data[[glue("{demo}_{pop_est}")]], 0)) /
            sum(.data[[glue("{demo}_{pop_est}")]])
      ) %>%
      replace(is.na(.), 0)
  }
}
