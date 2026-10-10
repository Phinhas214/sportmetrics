# result analysis

# needs to be discussed but I'm using these thresh holds for now
# H1 redundant if p ≥ 0.05 or delta_r2 < 0.01
# H2 too noisy if reliability < 0.5; moderate from 0.5 to 0.7; reliable from 0.7 
# H3 no real spread if true_sd is too small to matter in the metric’s own units (this needs a judgment based on the metric used). 

result_analysis <- read.csv("data/phase1_results.csv")

result_analysis$conclusion <- c("Not Redundant", "Not Redundant", "Moderate Reliability", "Moderate Reliability", "Reliable", "Real Spread", "Real Spread", "???")


write.csv(result_analysis, "data/phase1_result_analysis.csv", row.names = FALSE)
