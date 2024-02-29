install.packages("tidyverse")
install.packages("tidyr")
install.packages("rlist")
install.packages("reshape2")
install.packages("dplyr")
install.packages("tibble")
install.packages("lubridate")
install.packages("ggplot2")
install.packages("scales")
install.packages("knitr")


library("tidyverse")
library("tidyr")
library("rlist")
library("reshape2")
library("dplyr")
library("tibble")
library("lubridate")
library("ggplot2")
library("scales")
library("knitr")

types_memberships <- c('casual', 'member')
csv_path <- "./full_data.csv"
rides_df <- read_csv(csv_path, na = c("", "NA", "\\N"))

# Percentage and number of rides per month per membership

month_rides_tv <- rides_df %>% 
  count(month = month(started_at), member_casual) %>% #summarizes, no need to summarize later
  dcast(month ~ member_casual, value.var = "n") %>%
  mutate(total = member + casual) %>%
  mutate(casual_percent=100*casual/total, member_percent= 100*member/total)

ggplot(month_rides_tv %>%
         select(month, casual, member)  %>%
         melt(id.vars = "month", variable.name = "membership")
      )+
  labs(title="Number of trips by membership in 2023") +
  ylab("Trips") +
  geom_line(mapping =aes(x= month, y = value, color = membership)) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(breaks=seq(0, 12, 2)) +
  expand_limits(x=1, y=0)

max_p_casuals <- as.character(
  round(max(moth_rides_tv$casual_percent), 1)
)

ggplot(moth_rides_tv %>%
         select(month, casual_percent, member_percent)  %>%
         melt(id.vars = "month", variable.name = "membership")
       ) +
  labs(title="Percentage of trips by membership in 2023") +
  ylab("percent(%)") +
  geom_area(position = position_fill(), mapping = aes(x= month, y = value, fill = membership)) + 
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks=seq(0, 12, 2)) +
  annotate("text", x = 7, y = 0.5, label=paste("Casuals: ", max_p_casuals) )

# Get the top 10 stations of each type of membership in the year

station_rides <- rides_df %>% 
  drop_na(start_station_name) %>%
  count(start_station_name, member_casual)

most_used <- list()
for (member_type in types_memberships){
  most_used_member <- station_rides %>%
    filter(member_casual == member_type) %>%
    arrange(desc(n)) %>%
    head(10)
  most_used <- list.append(most_used, most_used_member)
}
names(most_used) <- types_memberships
most_used <- data.frame(most_used)

# Get the average duration of each type of membership per month

duration_rides_m <- rides_df %>%
  mutate(duration = difftime(ended_at, started_at, units="mins")) %>%
  mutate(month = month(started_at)) %>%
  select(member_casual, month, duration) %>%
  group_by(member_casual, month) %>%
  summarize(avg_duration = round(mean(duration), digits= 1) ) %>%
  arrange(month, member_casual)

avg_duration_casual <- as.character( round( (duration_rides_m %>% 
  filter(member_casual== "casual") %>%
  summarize(result = mean(avg_duration))) $ result, 1) )
avg_duration_member <- as.character( round( (duration_rides_m %>% 
  filter(member_casual== "member") %>%
  summarize(result = mean(avg_duration))) $ result, 1) )

ggplot(duration_rides_m)+
  labs(title="Duration of trips by month in 2023") +
  ylab("minutes") +
  geom_point(mapping = aes(x= month, y = avg_duration, color = member_casual, alpha=0.5)) +
  guides(alpha = FALSE, color = guide_legend(title="membership")) +
  annotate("text", x = 7, y = 20, label=paste("Avg casuals: ", avg_duration_casual, "mins") ) +
  annotate("text", x = 7, y = 8, label=paste("Avg members: ", avg_duration_member, "mins") ) +
  scale_x_continuous(breaks=seq(0, 12, 2)) +
  geom_smooth(method = "lm", mapping = aes(x= month, y = avg_duration, color = member_casual)) +
  expand_limits(x=1, y=0)
# Get the average duration of each type of membership per month
# And do a ratio between electric and classic bikes

rtype_ratio <- rides_df %>% 
  filter(rideable_type != "docked_bike") %>%
  count(month = month(started_at), member_casual, rideable_type) %>%
  dcast(month + member_casual ~ rideable_type , value.var = "n") %>%
  mutate(ratio = round(electric_bike/classic_bike, 2)) %>%
  select(month, member_casual, ratio) %>%
  dcast(month ~ member_casual , value.var = "ratio")

ggplot(rtype_ratio %>%
         melt(id.vars = "month", variable.name = "membership")
      ) +
  labs(title="Ratio trips Electric/Classic bikes") +
  ylab("Ratio") +
  geom_line(mapping = aes(x= month, y = 1.0, alpha= 0.33)) +
  guides(alpha = FALSE) +
  geom_line(mapping = aes(x= month, y = value, color = membership)) +
  annotate("text", x= 6, y = 2, label="More electric bike rides") +
  scale_x_continuous(breaks=seq(0, 12, 2)) +
  expand_limits(y=0.75)

# count rides by time of the day in all year

hours_rides <- rides_df %>% 
  count(weekday = wday(started_at), member_casual) %>% #summarizes, no need to summarize later
  dcast(weekday ~ member_casual, value.var = "n") %>%
  mutate(casual=100*casual/sum(casual), member= 100*member/sum(member))

ggplot(hours_rides %>%
        melt(id.vars = "weekday", variable.name = "membership")
      ) +
  labs(title="Average trips of each day in 2023") +
  ylab("trips") +
  geom_line(mapping = aes(x= weekday, y = value)) +
  facet_wrap(~membership)+
  scale_x_continuous(breaks = 1:7, 
                     labels = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
                     ) +
  expand_limits(y=10)






