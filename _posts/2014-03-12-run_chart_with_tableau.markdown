---
layout: post
title:  "Run Charts With Tableau"
date:   2014-03-12 14:48:00
author: Alexis Guinebertiere
categories: calcs
excerpt: How does this work again?
published: true
---

### What is a run chart? ###

A run chart is a simpler form of a control chart. Here are the run chart characteristics:
- Its centerline is the median of the points
- Rule #1 is to check for the number of runs. A run is a series on consecutive points above or below the centerline. Check that the number of runs is within acceptable limits (see below for what this means).
- Rule #2 is to check the length of the longest run.
- Rule #3 is to check for trends, or series of consecutive points that increase or decrease.

If any of the rules above is violated, you are likely to have detected a special cause. You would then have to find it and either incorporate it into your process or mitigate it. This would stabilize your process and you can then work on improving it.

### Rule \#1: count the number of runs ###

Rule \#1 is a two-step process. First we need to count the runs, then we check if this count is within acceptable boundaries.

#### Counting the runs ####

The run chart below is counting the number of runs, or consecutive points that are above or below the centerline. In the example below, we have 25 data points, and 9 runs.

![Run Count]({{ site.url }}/assets/2014-03-12_nb_runs.png)

Notice that some points are on the median line. You can include those in the current run, e.g. the second point in run \#6 is right on the median line, but we include it in run \#6.

The table calc to compute the `[Run number]` for the current point is the following:

```
previous_value(1)+
iif( sum(Sales) = window_median( sum(Sales))
    or (sum(Sales)-window_median( sum(Sales)))
    * (lookup(sum(Sales),-1)-window_median(sum(Sales)))
    > 0
    ,0, 1, 0 )
```

In the `iif`, we first test to see if this point is right on the median line. In that case, we stay in the current run, and add `0` to the current run number.

If the point is not on the median line, we check whether it is on the same side of the centerline as the previous point. To do this, we compute the difference between the last point and the median, and the difference between the current point and the median. For the points to be on the same side, these differences should have the same sign (both numbers are positive or both numbers are negative). To test this, we simply multiply those numbers together and check that the result is positive.

If the numbers are on the same side of the centerline, we stay on the same run number, otherwise we add 1 to the previous run number.

#### Checking if count is within acceptable limits ####

Next up is to check if the number of runs is within acceptable limits.
This varies with the number of points (or the number of observations) you have, excluding observations that fall on the median line.

![Run Count Limits]({{ site.url }}/assets/2014-03-12_run_count_limits.png)

[Download the excel spreadsheet here]({{ site.url }}/assets/run_count_limits.xlsx)

### Rule \#2: find the longest run ###

The second rule asks us to check for the longest run. A run longer than 7 points ( for sample sizes less than 20 points ) or 8 points ( for larger sample sizes ) indicates that your process has a special cause. The chart below has a longest run of 6, therefore rule #2 does not detect a special cause.

![Longest Run]({{ site.url }}/assets/2014-03-12_longest_runs.png)

To compute the length within a run, we use the following table calculation for `[Run length]`:

```
iif( zn( lookup( [Run number], -1 ) ) = [Run number],
// increase previous count by 1
previous_value(1)+1,
// start from 1 again
1 )
```

The `iif` checks if the run number for the current point is the same as for the previous point. If so, the run length increases by 1. Otherwise, we start at 1 again.

And now to find the largest run length, we simply do a window_max on the above:

```
window_max( [Run length] )
```

### Rule \#3: find longest trend ###

A trend is a series of consecutive points moving in the same direction, either increasing or decreasing. If your longest trend is 6 or 7, the rule is triggered ; you have likely found a special cause!

Here's what the length of a trend will look like on our data:

![Run Count Length Of Trend]({{ site.url }}/assets/2014-03-12_length_of_trend.png)

As you can see, we are well under 6 or 7, so this rule, once again, is not triggered.

To figure out the length of the trend at a particular point, we're going to compute:

- the difference betwen 2 points back and 1 point back
- the difference between 1 point back and the current point
- finally multiply those two numbers to check if they're of the same sign

If they are of the same sign, the multiplication will be positive. In that case, we're in a trend, and we add one to the previous trend count. If not, we start again from 1:

```
iif( ( lookup( sum(Sales), -1 ) - sum(Sales) )
    *
    ( lookup( sum(Sales), -2 ) - lookup( sum(Sales), -1 ) ) > 0,
    previous_value(1) + 1,
    1, 1 )
```
