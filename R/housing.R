housing_analysis <- function(housing, bg_pred) {
  left_join(housing, bg_pred, c(
    "state",
    "county",
    "tract",
    "block_group",
    "block"
  )) %>%
    select(state, county, tract, block_group, block, name, address_housing, department, pred_count, in_max_tb, gt_p50) %>%
    drop_na() %>% unique() %>% group_by(department, state, county, tract, block_group, block) %>%
    mutate(
      num_housing_units_mtb = if_else(in_max_tb == TRUE, 1, 0),
      num_housing_units_gt_p50 = if_else(gt_p50 == TRUE, 1, 0),
    ) %>%
    group_by(department) %>%
    summarise(
      num_ph_dept = n(),
      num_housing_units_mtb = sum(num_housing_units_mtb),
      num_housing_units_gt_p50 = sum(num_housing_units_gt_p50),
      pct_mtb = num_housing_units_mtb/num_ph_dept,
      pct_gt_p50 = num_housing_units_gt_p50 / num_ph_dept
    ) %>% distinct()
    
}
