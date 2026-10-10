- reliability using the split-half method It splits the player PAs into two piles multiple times, randomly shuffling them each time. Then it looks at player performance correlation between those piles. Luck is different in each pile so the only reason why those piles can correlate to each other is talent. Finally we combine both piles using Spearman-Brown prediction formula for split-half reliability adjustment -> aka more data = more stable metric. 
    - Motivation behind this is that each players output has a mix of luck and talent. We want to know how much of the output driven by the talent. Shuffling the multiple times and splitting the data into two piles is going to reduce the effect of luck in the output metric. 

- discriminability: spread of values measured through variance contributed from talent of each player. We want to use metrics to rank players otherwise it's only measuring differences in luck.  

    - How spread out are the players and how much of that spread is real talent. Because reliability can tell us the contribution of talent to the metric but if all players have very similar talent the metric becomes useless for ranking. 
    - There's an issue with calculating coefficnet of variance (cv) in discriminability.R. The function doesn't consider what happens when calculating a metric with that has positive and negative values with a potential average of 0. Since coefficient of variance = standard deviation / mean. if we have a 0 or close to 0 mean our cv will blow up and start to be a meanigless number. 
        - E.g: in baseball the metric WPA (Win Probability Added) has its average set to 0. Calculating cv for this metric will tell us nothing. 
        - Proposal: 
            1. We could either get rid of cv since we can get discriminability values from true_sd. cv doesn't really contribute to the question of discriminability directly since it uses observed standard deviation (which includes luck), this makes it not a fully controlled value to answer how players really differ. true_sd can be the main result of discriminability. 
            2. We could keep cv and just put a warning whenever our metric has values less than or equal to 0. 






## `test_discriminability()`: cv is meaningless for metrics without a true zero (WPA, WAR, wRAA)

### Problem
There's an issue with calculating the coefficient of variation (cv) in `discriminability.R`. The function doesn't consider what happens when the metric doesn't have a true zero (a zero that means "none of it" instead of a 0 that is arbitrary, think of farenheit or celcius where 0 doesn't actually mean no heat). Since coefficient of variation = standard deviation / mean, moving where zero is changes the mean but not the spread, so the cv changes even though the players are exactly the same. If we have a 0 or close to 0 mean, our cv will blow up and become a meaningless number.

- E.g.: in baseball the metric WPA (Win Probability Added) has its average set to 0. Calculating cv for this metric will tell us nothing.

### Example
```r
df <- data.frame(wpa = c(1.8, -0.6, 0.3, -1.2, 0.2))
r1 <- test_discriminability(df, "wpa")
c(r1$sd, r1$cv)
#> [1]  1.131371  11.313708

df$wpa_minus_02 <- df$wpa - 0.2   # same players, zero moved by 0.2
r2 <- test_discriminability(df, "wpa_minus_02")
c(r2$sd, r2$cv)
#> [1]   1.131371 -11.313708
```


We have the same spread (sd = 1.13), but cv goes from 11.3 to -11.3.


Since the package is meant to be sport-agnostic, and a lot of metrics in other sports are also centered on 0 this issue will come up for every sport metric. 

Proposal

1. We could get rid of cv, since we can get discriminability values from `true_sd`. cv doesn't really contribute to the question of discriminability directly, since it uses observed standard deviation (which includes luck). This makes it not a fully controlled value to answer how players really differ through their talent alone. `true_sd` can be the main result of discriminability.
2. We could keep cv and just add a warning whenever our metric has negative values (any(x < 0)).
   - A warning can't catch every case (e.g. WPA + 10 has no negative values but cv is still meaningless), so we should also add a note in the docs that cv only makes sense when zero means "none of it".

I'd lean towards option 1, since `true_sd` answers the discriminability question better.




- calculating H2 reliability for defense DRS (Defensive Runs Saved) metric doesn't use test_reliability because we can't get per game data fro DRS. This is because DRS is calculated for each season. There are no per game DRS values (only for seaons) so you can't divide DRS into two halves. 
    - I'm using corellation between this season and the next to calculate H3 reliability scores. 
    - expect correlation to be lower than H2 scores for offense metrics because there's more variability per player between each season (age, injury, position change)
    - H3 discriminability scores also use this DRS score so H3 will also be affected downstream. 
  

- Reliability scores are low maybe because we're filtering players whose PA >= 300. 
  - Most likely only the better players will get chosen multiple times for PAs and the opposite for not that good players. 
  - This means that we have a bias towards better players which makes our selected players similar to each other. 
  - narrow talent spread
  - max PAs/season record is 778 by Jimmy Rollins. 
  
  
  
  
- needs to be discussed but I'm using these thresh holds for now
- H1 redundant if p ≥ 0.05 or delta_r2 < 0.01
- H2 too noisy if reliability < 0.5; moderate from 0.5 to 0.7; reliable from 0.7 
- H3 no real spread if true_sd is too small to matter in the metric’s own units (this needs a judgment based on the metric used, I'm not too familiar with baseball metrics). 
  





