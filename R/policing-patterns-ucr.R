# Arrest patterns analysis using the FBI's Uniform Crime Reporting statistics.
policing_patterns_ucr <- function(ucr_data, raw_jurisdictions) {
  jur_summary <- raw_jurisdictions %>%
    group_by(client) %>%
    mutate(
      black = sum(black_alone),
      white = sum(white_alone),
      asian = sum(asian_alone),
      latino = sum(latino_alone)
    ) %>%
    select(client, black, white, asian, latino) %>%
    unique() %>%
    pivot_longer(black:latino,
      names_to = "race",
      values_to = "population"
    )

  ucr_data$race <- recode(ucr_data$key,
    "Black or African American" = "black",
    "Asian" = "asian",
    "White" = "white"
  )

  clients_with_no_data <- c("ocoeepd", "ftmyerspd", "ocalapdcom", "templeterracepd", "ocfl", "cpd")

  all_depts_uct_per_capita <- ucr_data %>%
    filter(race %in% c("black", "asian", "white") & type == "all" &
      data_year >= 2017 &
      !client %in% clients_with_no_data) %>%
    left_join(jur_summary, by = c("client", "race")) %>%
    mutate(
      per_capita = value / population,
      race = fct_relevel(race, c("asian", "white", "black"))
    ) %>%
    group_by(client, race) %>%
    mutate(
      per_capita_avg = mean(per_capita)
    ) %>%
    select(key, client, race, type, per_capita_avg) %>%
    ungroup() %>%
    unique() %>%
    group_by(client) %>%
    mutate(
      times = per_capita_avg / per_capita_avg[race == "white"]
    )
}


plot_policing_patterns_disprop <- function(all_depts_uct_per_capita) {
  depts_of_interest <- all_depts_uct_per_capita %>%
    filter(race == "black" & times > 2) %>%
    select(client) %>%
    unique()

  plot_data <- all_depts_uct_per_capita %>% filter(client %in% depts_of_interest$client)

  plot <- plot_data %>% ggplot(aes(x = client, y = per_capita_avg, fill = race)) +
    geom_bar(position = "dodge", stat = "identity") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(glue("out/plots/policing_patterns_ucr.png"), plot, width = 10, height = 7)
  plot_data %>% write_csv(glue("out/dataframes/policing_patterns_ucr.csv"))
  return(glue("out/dataframes/policing_patterns_ucr.csv"))
}
