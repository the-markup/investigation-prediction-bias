rank_and_label <- function(bg_demo, bg_pred_count, demo_type) {
  left_join(bg_demo, bg_pred_count, c("department", "state", "county", "tract", "block_group")) %>%
    group_by(department, state, county, tract, block_group) %>%
    mutate(
      geoid = paste0(state, county, tract, block_group),
      has_predictions = if_else(is.na(has_predictions), FALSE, TRUE),
      pred_count = replace_na(pred_count, 0)
    ) %>%
    group_by(department) %>%
    arrange(desc(pred_count), desc(glue("total_{demo_type}_est")), .by_group = TRUE) %>%
    mutate(
      pred_rank = percent_rank(pred_count),
      pred_pop_rank = n():1,
      window_size = round(n() * 0.05),
      window_offset = floor(window_size / 2),
      middle_value = floor(n() / 2),
      bg_count = n(),
      max_ub = max(pred_pop_rank),
      max_lb = max(pred_pop_rank) - window_size,
      med_ub = middle_value + window_offset,
      med_lb = middle_value - window_offset,
      count_min = sum(if_else(pred_count == min(pred_count), 1, 0)),
      min_ub = if_else(count_min > window_size,
        count_min, min(pred_pop_rank) + window_size
      ),
      min_lb = if_else(count_min > window_size,
        count_min - window_size, as.double(min(pred_pop_rank))
      ),
      ## We also ran this analysis such that we
      ## include all zero prediction block groups in the least targeted blocks.
      # min_lb = if_else(count_min > window_size,
      #                  1, as.double(min(pred_pop_rank))),
    ) %>%
    mutate(
      in_max_tb = if_else(pred_pop_rank >= max_lb & pred_pop_rank <= max_ub, TRUE, FALSE),
      in_med_tb = if_else(pred_pop_rank >= med_lb & pred_pop_rank <= med_ub, TRUE, FALSE),
      in_min_tb = if_else(pred_pop_rank >= min_lb & pred_pop_rank <= min_ub, TRUE, FALSE)
    ) %>%
    mutate(
      iqr_upper = quantile(pred_count, probs = 0.75) + 1.5 * IQR(pred_count),
      iqr_lower = abs(quantile(pred_count, probs = 0.25) - 1.5 * IQR(pred_count)),
      median_count = quantile(pred_count, probs = 0.50),
      gt_p50 = if_else(pred_count > median_count, TRUE, FALSE),
      lt_p50 = if_else(pred_count < median_count, TRUE, FALSE),
      gt_iqr_upper = if_else(pred_count >= iqr_upper, TRUE, FALSE),
      lt_iqr_lower = if_else(pred_count <= iqr_lower, TRUE, FALSE),
      bw_p90_p100 = if_else(pred_count > quantile(pred_count, probs = 0.90) & pred_count <= quantile(pred_count, probs = 1), TRUE, FALSE),
      bw_p80_p90 = if_else(pred_count > quantile(pred_count, probs = 0.80) & pred_count < quantile(pred_count, probs = 0.90), TRUE, FALSE),
      bw_p70_p80 = if_else(pred_count > quantile(pred_count, probs = 0.70) & pred_count < quantile(pred_count, probs = 0.80), TRUE, FALSE),
      bw_p60_p70 = if_else(pred_count > quantile(pred_count, probs = 0.60) & pred_count < quantile(pred_count, probs = 0.70), TRUE, FALSE),
      bw_p50_p60 = if_else(pred_count > quantile(pred_count, probs = 0.50) & pred_count < quantile(pred_count, probs = 0.60), TRUE, FALSE),
      bw_p40_p50 = if_else(pred_count > quantile(pred_count, probs = 0.40) & pred_count < median_count, TRUE, FALSE),
      bw_p30_p40 = if_else(pred_count > quantile(pred_count, probs = 0.30) & pred_count < quantile(pred_count, probs = 0.40), TRUE, FALSE),
      bw_p20_p30 = if_else(pred_count > quantile(pred_count, probs = 0.20) & pred_count < quantile(pred_count, probs = 0.30), TRUE, FALSE),
      bw_p10_p20 = if_else(pred_count > quantile(pred_count, probs = 0.10) & pred_count < quantile(pred_count, probs = 0.20), TRUE, FALSE),
      lt_p10 = if_else(pred_count < quantile(pred_count, probs = 0.10), TRUE, FALSE),
    ) %>%
    select(
      department,
      pred_count,
      pred_pop_rank,
      state,
      county,
      tract,
      block_group,
      geoid,
      contains(c("_ub", "_lb", "_est")),
      contains(c("gt", "lt", "bw", "in", "iqr")),
      # Useful for debugging
      # min_ub,
      # min_lb,
      # count_min,
      # window_size
    ) %>%
    ungroup()
}


rank_and_label_blocks <- function(bg_pred_count, ignore_list) {
  bg_pred_count %>%
    filter(department %in% ignore_list == FALSE) %>%
    group_by(department, state, county, tract, block_group, block) %>%
    mutate(
      pred_count = replace_na(pred_count, 0)
    ) %>%
    group_by(department) %>%
    arrange(desc(pred_count), .by_group = TRUE) %>%
    mutate(
      pred_rank = percent_rank(pred_count),
      pred_pop_rank = n():1,
      window_size = round(n() * 0.05),
      window_offset = floor(window_size / 2),
      middle_value = floor(n() / 2),
      bg_count = n(),
      max_ub = max(pred_pop_rank),
      max_lb = max(pred_pop_rank) - window_size,
      med_ub = middle_value + window_offset,
      med_lb = middle_value - window_offset,
      count_min = sum(if_else(pred_count == min(pred_count), 1, 0)),
      min_ub = if_else(count_min > window_size,
        count_min, min(pred_pop_rank) + window_size
      ),
      min_lb = if_else(count_min > window_size,
        count_min - window_size, as.double(min(pred_pop_rank))
      ),
    ) %>%
    mutate(
      in_max_tb = if_else(pred_pop_rank >= max_lb & pred_pop_rank <= max_ub, TRUE, FALSE),
      in_med_tb = if_else(pred_pop_rank >= med_lb & pred_pop_rank <= med_ub, TRUE, FALSE),
      in_min_tb = if_else(pred_pop_rank >= min_lb & pred_pop_rank <= min_ub, TRUE, FALSE)
    ) %>%
    mutate(
      iqr_upper = quantile(pred_count, probs = 0.75) + 1.5 * IQR(pred_count),
      iqr_lower = abs(quantile(pred_count, probs = 0.25) - 1.5 * IQR(pred_count)),
      gt_p95 = if_else(pred_rank > 0.95, TRUE, FALSE),
      gt_p90 = if_else(pred_rank > 0.90, TRUE, FALSE),
      gt_p75 = if_else(pred_rank > 0.75, TRUE, FALSE),
      gt_p50 = if_else(pred_rank > 0.50, TRUE, FALSE),
      bw_p25_p75 = if_else(pred_rank > 0.25 & pred_rank < 0.75, TRUE, FALSE),
      lt_p50 = if_else(pred_rank < 0.50, TRUE, FALSE),
      lt_p25 = if_else(pred_rank < 0.25, TRUE, FALSE),
      lt_p10 = if_else(pred_rank < 0.10, TRUE, FALSE),
      lt_p5 = if_else(pred_rank < 0.05, TRUE, FALSE),
      gt_iqr_upper = if_else(pred_count >= iqr_upper, TRUE, FALSE),
      lt_iqr_lower = if_else(pred_count <= iqr_lower, TRUE, FALSE),
    ) %>%
    select(
      department,
      pred_count,
      pred_pop_rank,
      state,
      county,
      tract,
      block_group,
      block,
      contains(c("_ub", "_lb", "_est")),
      contains(c("gt", "lt", "bw", "in", "preds")),
    )
}
