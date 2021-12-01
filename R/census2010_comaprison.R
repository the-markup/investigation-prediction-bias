
# Calculate demographic information for the stable block groups.
# This is used in the block level race analysis of the methodology

census_2010_boi <- function(stable_bg) {
  stable_bg %>%
    group_by(client, state, county, tract, block_group) %>%
    mutate(
      preds_in_bg = sum(count),
      mtb_pred_count = max(count),
      mtb_black_pop = black_percentage[which.max(count)],
      mtb_white_pop = white_percentage[which.max(count)],
      mtb_asian_pop = asian_percentage[which.max(count)],
      mtb_latino_pop = latino_percentage[which.max(count)],
      bg_median_black_pop = median(black_percentage, na.rm = TRUE),
      bg_median_white_pop = median(white_percentage, na.rm = TRUE),
      bg_median_asian_pop = median(asian_percentage, na.rm = TRUE),
      bg_median_latino_pop = median(latino_percentage, na.rm = TRUE)
    ) %>%
    select(client, state, county, tract, block_group, preds_in_bg, contains("mtb"), contains("bg_median")) %>%
    unique() %>%
    filter(preds_in_bg > 0)
}
