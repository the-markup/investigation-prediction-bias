library(tidyverse)
library(glue)

filter_predictions_dept_confirmation <- function(predictions, department) {
  dept_dates <- department %>% select(client, analysis_start_date, analysis_end_date, confirmed_start, confirmed_end)
  left_join(predictions, dept_dates, by = c("department" = "client")) %>%
    filter(date >= analysis_start_date & date <= analysis_end_date)
}

aggergate_predictions_to_block_groups <- function(data) {
  data %>%
    group_by(department, state, county, tract, block_group) %>%
    summarise(
      pred_count = n(),
      has_predictions = if_else(n() > 0, TRUE, FALSE),
      state,
      department,
      county,
      tract,
      block_group
    ) %>%
    distinct()
}

aggergate_predictions_to_blocks <- function(data) {
  data %>%
    select(
      report_id,
      department,
      date,
      state,
      county,
      tract,
      block_group,
      block
    ) %>%
    group_by(department, state, county, tract, block_group, block) %>%
    summarise(
      pred_count = n(),
      has_predictions = if_else(n() > 0, TRUE, FALSE),
      state,
      department,
      county,
      tract,
      block_group,
      block
    ) %>%
    distinct()
}

aggergate_predictions_to_lat_long <- function(data) {
  data %>%
    # select(
    #   report_id,
    #   department,
    #   date,
    #   lat,
    #   lon,
    #   address,
    #   incident_types
    # ) %>%
    group_by(department, lat, lon) %>%
    summarise(
      pred_count = n(),
      incident_types = incident_types %>% unique() %>% paste0( collapse = "||"),
      address = address_x %>% unique() %>% paste0(collapse = "||")
    ) %>%
    distinct()
}
# aggergate_predictions_to_lat_long(raw_predictions)
 
calculate_block_group_population_estimates <- function(data) {
  data %>%
    select(
      geoid,
      client,
      name,
      state,
      county,
      tract,
      block_group,
      ends_with("moe"),
      ends_with("alone"),
      contains("_and_"),
      contains("frl"),
      contains("percentage"),
      contains("household"),
      contains("greater"),
      contains("less_than_10"),
      -starts_with("two_or_more"),
      -starts_with("pacific_islander"),
      -ends_with("exposures"),
    ) %>%
    rename(
      department = client,
      total_income_est = total_estimate_household,
      lt.45k_est = eligible_for_frl,
      bw.75.100k_est = `75_and_100`,
      bw.75.100k_moe = `75_and_100_moe`,

      # NOTE: This is mislabeled, the census actually provides information for 125-150k.
      bw.120.150k_est = `120_and_150`,
      bw.120.150k_moe = `120_and_150_moe`,
      gt.200k_est = `greater_than_200`,
      gt.200k_moe = `greater_than_200_moe`
    ) %>%
    mutate(
      lt.45k_moe = round(sqrt(`less_than_10_moe` * `less_than_10_moe` +
        `10_and_15_moe` * `10_and_15_moe` +
        `15_and_20_moe` * `15_and_20_moe` +
        `20_and_25_moe` * `20_and_25_moe` +
        `25_and_30_moe` * `25_and_30_moe` +
        `30_and_35_moe` * `30_and_35_moe` +
        `35_and_40_moe` * `35_and_40_moe` +
        `40_and_45_moe` * `40_and_45_moe`))
    ) %>%
    mutate(
      asian_est = asian_alone,
      black_est = black_alone,
      latino_est = latino_alone,
      white_est = white_alone,
      total_race_est = total_estimate_alone,
      asian_ub = asian_alone + asian_moe,
      black_ub = black_alone + black_alone_moe,
      latino_ub = latino_alone + latino_moe,
      white_ub = white_alone + white_alone_moe,
      total_ub = total_estimate_alone + total_estimate_alone_moe,
      asian_lb = pmax(asian_alone - asian_alone_moe, 0),
      black_lb = pmax(black_alone - black_alone_moe, 0),
      latino_lb = pmax(latino_alone - latino_moe, 0),
      white_lb = pmax(white_alone - white_alone_moe, 0),
      total_race_lb = pmax(total_estimate_alone - total_estimate_alone_moe, 0),
      lt.45k_ub = pmax(lt.45k_est + lt.45k_moe, 0),
      bw.75.100k_ub = pmax(bw.75.100k_est + bw.75.100k_moe, 0),
      bw.120.150k_ub = pmax(bw.120.150k_est + bw.120.150k_moe, 0),
      gt.200k_ub = pmax(gt.200k_est + gt.200k_moe, 0),
      total_income_ub = total_income_est + total_estimate_household_moe,
      lt.45k_lb = pmax(lt.45k_est - lt.45k_moe, 0),
      bw.75.100k_lb = pmax(bw.75.100k_est - bw.75.100k_moe, 0),
      bw.120.150k_lb = pmax(bw.120.150k_est - bw.120.150k_moe, 0),
      gt.200k_lb = pmax(gt.200k_est - gt.200k_moe, 0),
      total_income_lb = pmax(total_income_est - total_estimate_household_moe, 0)
    ) %>%
    mutate(
      asian_est = asian_alone,
      black_est = black_alone,
      latino_est = latino_alone,
      white_est = white_alone,
      total_race_est = total_estimate_alone,
      asian_ub = asian_alone + asian_moe,
      black_ub = black_alone + black_alone_moe,
      latino_ub = latino_alone + latino_moe,
      white_ub = white_alone + white_alone_moe,
      total_race_ub = total_estimate_alone + total_estimate_alone_moe,
      asian_lb = pmax(asian_alone - asian_alone_moe, 0),
      black_lb = pmax(black_alone - black_alone_moe, 0),
      latino_lb = pmax(latino_alone - latino_moe, 0),
      white_lb = pmax(white_alone - white_alone_moe, 0),
      total_race_lb = pmax(total_estimate_alone - total_estimate_alone_moe, 0),
    )
}
