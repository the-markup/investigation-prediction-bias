# _targets.R file
library(targets)
library(tarchetypes)

source("R/preprocessing/preprocessing.R")
source("R/preprocessing/rank-and-label.R")
source("R/preprocessing/calculate-demographic-proportions.R")

source("R/disparate_impact/bg_comparison_methods.R")
source("R/disparate_impact/jur_comparison_methods.R")

source("R/disparate_impact/correlation.R")
source("R/disparate_impact/demo_composition_at_deciles.R")
source("R/housing.R")
source("R/arrests.R")
source("R/policing-patterns-ucr.R")
source("R/census2010_comaprison.R")


tar_option_set(packages = c("tidyverse", "glue"))
options(tidyverse.quiet = TRUE)



## Generate Config
analysis_config <- tibble(
  analysis_pop_type = c("bg", "bg", "jur", "jur"),
  analysis_demo = c("race", "income", "race", "income")
)

## Get labels
get_pop_buckets <- function(pop_type) {
  if (pop_type == "bg") {
    c("in_max_tb", "in_med_tb", "in_min_tb", "total")
  } else {
    c("gt_p50", "lt_p50")
  }
}

get_demo_buckets <- function(demo) {
  if (demo == "race") {
    c("asian", "black", "latino", "white")
  } else {
    jur.demo <- c("lt.45k", "bw.75.100k", "bw.120.150k", "gt.200k")
  }
}

get_plot_args <- function(pop_type) {
  if (pop_type == "bg") {
    c("inc_at_prank", "demo_comp_all", "at_prank_gt_total", "corr")
  } else {
    c("prank_has_maj")
  }
}


build_di_plots <- function(plot_name, data, demo_type, args, departments) {
  if (plot_name == "inc_at_prank") {
    mean_demo_proportion_increase_at_prank(data, args, demo_type, departments)
  } else if (plot_name == "at_prank_gt_total") {
    demo_proportion_at_prank_compared_to_total(data, args, demo_type, departments)
  } else if (plot_name == "prank_has_maj") {
    jur_demographic_majority_compared_to_prank_median(data, args, demo_type, departments)
  } else if (plot_name == "demo_comp_all") {
    demo_comp_comparison_all_dept(data, demo_type, departments)
  }
}


## Target Lists
in_data_targets <- list(
  tar_target(
    all_predictions_file,
    "in/all_predictions.csv",
    format = "file"
  ),
  tar_target(
    all_jurisdictions_file,
    "in/all_jurisdictions.csv",
    format = "file"
  ),
  tar_target(
    departments_file,
    "in/departments.csv",
    format = "file"
  ),
  tar_target(
    raw_predictions,
    read_csv(all_predictions_file, col_types = cols())
    # %>%
    #   select(
    #     report_id,
    #     department,
    #     date,
    #     state,
    #     county,
    #     tract,
    #     block_group,
    #     block,
    #     block,
    #     lat,
    #     lon,
    #     address_x,
    #     incident_types
    #   )
  ),
  tar_target(
    raw_jurisdictions,
    read_csv(all_jurisdictions_file, col_types = cols())
  ),
  tar_target(
    departments,
    read_csv(departments_file, col_types = cols()) %>%
      rename(
        client_name = `Client Name`,
        confirmed_start = `Confirmed Start Date`,
        confirmed_end = `Confirmed End Date`,
        active = Active
      ) %>%
      mutate(
        analysis_start_date = if_else(as.Date(confirmed_start) < first_prediction_date, first_prediction_date, as.Date(confirmed_start, "%Y-%m-%d")),
        analysis_end_date = if_else(confirmed_end == "Current", final_prediction_date, as.Date(confirmed_end, "%Y-%m-%d"))
      ) %>%
      filter(Usable == TRUE)
  )
)

preprocessing <- list(
  tar_target(
    dept_prediction_dates,
    raw_predictions %>% group_by(department) %>%
      mutate(
        first_prediction = min(date),
        last_prediction = max(date)
      ) %>% select(department, first_prediction, last_prediction) %>% distinct() %>%
      write_csv("out/dept_prediction_date_ranges.csv")
  ),
  tar_target(
    dept_usage_dates,
    departments %>%
      select(client_name, first_prediction_date, final_prediction_date, confirmed_start, confirmed_end, analysis_start_date, analysis_end_date) %>%
      write_csv("out/dept_usage_dates.csv")
  ),
  tar_target(
    predictions_for_analysis,
    filter_predictions_dept_confirmation(raw_predictions, departments) %>%
      filter(department %in% departments$client)
  ),
  tar_target(
    num_predictions,
    bg_pred %>% group_by(department)
      %>% mutate(num_preds = sum(pred_count))
      %>% select(department, num_preds)
      %>% unique()
      %>% ungroup()
      %>% left_join(departments, by = c("department" = "client"))
      %>% add_row(department = "Total", num_preds = sum(.$num_preds))
      %>% write_csv("out/prediction_count.csv")
  ),
  tar_target(
    bg_pred,
    aggergate_predictions_to_block_groups(predictions_for_analysis)
  ),
  tar_target(
    blocks_pred,
    aggergate_predictions_to_blocks(predictions_for_analysis)
  ),
  tar_target(
    bg_demo,
    calculate_block_group_population_estimates(raw_jurisdictions) %>%
      filter(department %in% departments$client)
  )
)

disparate_impact_targets <- tar_map(
  values = analysis_config,
  tar_target(
    args,
    expand.grid(
      pop_est = c("est", "lb", "ub"),
      demo = get_demo_buckets(analysis_demo),
      pop_buckets = get_pop_buckets(analysis_pop_type)
    )
  ),
  tar_target(
    bg_ranked_pop_bounds,
    rank_and_label(bg_demo, bg_pred, analysis_demo)
  ),
  tar_target(
    corr_race,
    corr_demo_predictions_race(bg_ranked_pop_bounds, departments)
  ),
  tar_target(
    corr_income,
    corr_demo_predictions_income(bg_ranked_pop_bounds, departments)
  ),
  tar_target(
    prop_groups,
    get_demo_proportions(
      bg_ranked_pop_bounds,
      analysis_pop_type,
      args$demo,
      args$pop_est,
      args$pop_buckets,
      analysis_demo
    ),
    pattern = map(args),
    iteration = "list"
  ),
  tar_target(
    demo_prop_buckets,
    prop_groups %>%
      reduce(inner_join, by = "department")
  ),
  tar_target(
    plot_args,
    get_plot_args(analysis_pop_type)
  ),
  tar_target(
    analysis_plots,
    build_di_plots(plot_args, demo_prop_buckets, analysis_demo, args, departments),
    pattern = map(plot_args),
    iteration = "list"
  )
)

arrest_targets <- list(
  tar_target(
    arrests_block_data_file,
    "in/block-level-prediction-arrest-counts.csv",
    format = "file"
  ),
  tar_target(
    uof_file,
    "in/uof.csv",
    format = "file"
  ),
  tar_target(
    arrests_fp,
    "in/arrests.csv",
    format = "file"
  ),
  tar_target(
    arrests_block_data,
    read_csv(arrests_block_data_file, col_types = cols())
  ),
  tar_target(
    bg_ranked_pop_bounds_arrest_race,
    rank_and_label(bg_demo, bg_pred, "race")
  ),
  tar_target(
    uof,
    read_csv(uof_file, col_types = cols())
  ),
  tar_target(
    arrests,
    read_csv(arrests_fp, col_types = cols(
      lat = col_double(),
      lon = col_double(),
      date = col_date(format = ""),
      race = col_factor(),
      success = col_logical(),
      address_location = col_logical(),
      geoid = col_factor(),
      block = col_double(),
      block_group = col_double(),
      tract = col_double(),
      county = col_double(),
      state = col_double(),
      ts = col_datetime(format = "")
    ))
  ),
  tar_target(
    arrests_per_capita,
    get_arrests_per_capita(arrests, bg_ranked_pop_bounds_arrest_race)
  ),
  tar_target(
    uof_per_capita,
    get_uof_per_capita(uof, bg_ranked_pop_bounds_arrest_race)
  ),
  tar_target(
    corr_arrest_preds,
    corr_arrests_predictions(arrests_block_data)
  ),
  tar_target(
    arrests_per_capita_plot,
    plot_arrests_per_capita(arrests_per_capita)
  ),
  tar_target(
    corr_arrest_preds_plot,
    plot_corr_arrest_preds(corr_arrest_preds)
  )
)

housing_targets <- list(
  tar_target(
    blocks_ranked_pop_bounds,
    rank_and_label_blocks(blocks_pred, c("indianapolis", "reading"))
  ),
  tar_target(
    housing_fp,
    "in/housing.csv",
    format = "file"
  ),
  tar_target(
    housing,
    read_csv(housing_fp, col_types = cols())
  ),
  tar_target(
    housing_preds,
    housing_analysis(housing, blocks_ranked_pop_bounds)
  ),
  tar_target(
    housing_block_map_file,
    "in/block-level-prediction-counts.csv",
    format = "file"
  ),
  tar_target(
    housing_block_map,
    read_csv(housing_block_map_file, col_types = cols())
  )
)

percentile_comparison_targets <- tar_map(
  values = tibble(
    analysis_demo = c("race", "income")
  ),
  tar_target(
    args,
    expand.grid(
      pop_est = c("est"),
      demo = get_demo_buckets(analysis_demo),
      pop_buckets = c("lt_p10", "bw_p10_p20", "bw_p20_p30", "bw_p30_p40", "bw_p40_p50", "bw_p50_p60", "bw_p60_p70", "bw_p70_p80", "bw_p80_p90", "bw_p90_p100")
    )
  ),
  tar_target(
    bg_ranked_pop_bounds,
    rank_and_label(bg_demo, bg_pred, analysis_demo)
  ),
  tar_target(
    big_prop_groups,
    get_demo_proportions(
      bg_ranked_pop_bounds,
      "bg",
      args$demo,
      args$pop_est,
      args$pop_buckets,
      analysis_demo
    ),
    pattern = map(args),
    iteration = "list"
  ),
  tar_target(
    big_demo_prop_buckets,
    big_prop_groups %>%
      reduce(inner_join, by = "department")
  ),
  tar_target(
    big_demo_prop_buckets_dept_join,
    left_join(big_demo_prop_buckets, departments %>% select(client, client_name), by = c("department" = "client"))
  ),
  tar_target(
    plot_demo_comp_all,
    demo_comp_comparison_all_pct_all_dept(big_demo_prop_buckets_dept_join, analysis_demo)
  ),
  tar_target(
    plot_demo_comp_per_dept,
    demo_comp_comparison_all_pct_per_dept(big_demo_prop_buckets_dept_join, analysis_demo)
  )
)

online_datasheet_targets <- list(
  tar_target(
    bg_ranked_pop_bounds_datasheet,
    rank_and_label(bg_demo, bg_pred, "race")
  ),
  tar_target(
    jurisdictions,
    departments %>%
      mutate(
        output_file = glue("{client}.html"),
        analysis_start_date = format(analysis_start_date, "%b %d, %Y"),
        analysis_end_date = format(analysis_end_date, "%b %d, %Y"),
        confirmed_start = format(confirmed_start, "%b %d, %Y"),
        confirmed_end = analysis_end_date
      ) %>%
      # filter(client != "reading" & client != "indianapolis") %>%
      # filter(client == "jacksonvilletx" ) %>%
      select(client, client_name, analysis_start_date, analysis_end_date, confirmed_start, confirmed_end, output_file)
  ),
  # tar_render(arrest_section, "datasheets/datasheet.Rmd"),
  # tar_render_rep(
  #   datasheet,
  #   "datasheets/datasheet.Rmd",
  #   params = tibble(
  #     client = jurisdictions$client,
  #     client_name = jurisdictions$client_name,
  #     first_prediction_date = jurisdictions$analysis_start_date,
  #     final_prediction_date = jurisdictions$analysis_end_date,
  #     confirmed_start = jurisdictions$confirmed_start,
  #     confirmed_end = jurisdictions$confirmed_end,
  #     output_file = jurisdictions$output_file
  #   ),
  #   batches = 2
  # ),
  tar_render_rep(
    datasheet_online,
    "datasheets/datasheet-online.Rmd",
    params = tibble(
      client = jurisdictions$client,
      client_name = jurisdictions$client_name,
      first_prediction_date = jurisdictions$analysis_start_date,
      final_prediction_date = jurisdictions$analysis_end_date,
      confirmed_start = jurisdictions$confirmed_start,
      confirmed_end = jurisdictions$confirmed_end,
      output_file = jurisdictions$output_file
    ),
    batches = 2
  )
)


pdf_datasheet_targets <- list(
  tar_target(
    bg_ranked_pop_bounds_datasheet,
    rank_and_label(bg_demo, bg_pred, "race")
  ),
  tar_target(
    jurisdictions,
    departments %>%
      mutate(
        output_file = glue("{client}-for-pdf.html"),
        analysis_start_date = format(analysis_start_date, "%b %d, %Y"),
        analysis_end_date = format(analysis_end_date, "%b %d, %Y"),
        confirmed_start = format(confirmed_start, "%b %d, %Y"),
        confirmed_end = analysis_end_date
      ) %>%
      # filter(client != "reading" & client != "indianapolis") %>%
      # filter(client == "jacksonvilletx" ) %>%
      select(client, client_name, analysis_start_date, analysis_end_date, confirmed_start, confirmed_end, output_file)
  ),
  tar_render_rep(
    datasheet,
    "datasheets/datasheet-pdf.Rmd",
    params = tibble(
      client = jurisdictions$client,
      client_name = jurisdictions$client_name,
      first_prediction_date = jurisdictions$analysis_start_date,
      final_prediction_date = jurisdictions$analysis_end_date,
      confirmed_start = jurisdictions$confirmed_start,
      confirmed_end = jurisdictions$confirmed_end,
      output_file = jurisdictions$output_file
    ),
    batches = 2
  )
)

policing_patterns_analysis <- list(
  tar_target(
    ucr_file,
    "in/ucr.csv",
    format = "file"
  ),
  tar_target(
    ucr_data,
    read_csv(ucr_file)
  ),
  tar_target(
    policing_patterns,
    policing_patterns_ucr(ucr_data, raw_jurisdictions)
  ),
  tar_target(
    plot_policing_patterns,
    plot_policing_patterns_disprop(policing_patterns)
  )
)

census_2010_blocks_analysis <- list(
  tar_target(stable_bg_file, "in/stable-bgs.csv", format = "file"),
  tar_target(
    stable_bg,
    read_csv(stable_bg_file, col_types = cols())
  ),
  tar_target(
    boi_2010,
    census_2010_boi(stable_bg)
  )
)


map_utils_pipeline <- list(
  tar_target(agg_pred_count, aggergate_predictions_to_lat_long(raw_predictions)),
  tar_target(
    agg_pred_count_file,
    agg_pred_count %>% write_csv("out/agg-pred-coords.csv")
  ),
  tar_target(
    agg_pred_count_file_per_dept,
    agg_pred_count %>%
      group_by(department) %>%
      select(lat, lon, department, pred_count) %>%
      group_walk(~ write_csv(.x, paste0("out/pred_count_by_dept/", .y$department, ".csv")))
  )
)


## Analysis Pipeline
list(
  in_data_targets,
  preprocessing,
  disparate_impact_targets,
  housing_targets,
  arrest_targets,
  percentile_comparison_targets,
  policing_patterns_analysis,
  census_2010_blocks_analysis
  # tar_render(arrest_section, "R/findings.Rmd", output_file = "../out/findings.pdf")
  # tar_render(cheatsheet, "R/jurisdiction-prop-cheatsheet.Rmd", output_file = "../out/jurisdiction-prop-cheatsheet.pdf")
)


## HTML Datasheets Pipeline
# list(
#   in_data_targets,
#   preprocessing,
#   map_utils_pipeline,
#   disparate_impact_targets,
#   housing_targets,
#   online_datasheet_targets
# )

# ## PDF Datasheets Pipeline
# ## Note: need to run html2pdf after you run this.
# list(
#   in_data_targets,
#   preprocessing,
#   map_utils_pipeline,
#   disparate_impact_targets,
#   housing_targets,
#   pdf_datasheet_targets
# )
