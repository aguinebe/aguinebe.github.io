---
layout: post
title:  "Control Charts Detection Rules With Table Calcs"
date:   2014-03-10 14:48:00
author: Alexis Guinebertiere
categories: calcs
excerpt: How does this work again?
published: true
---

In this article we'll discuss implementing [control charts] detection rules with Tableau. We'll assume here that you have determined the boundaries (also called limits) for your control chart. Typically this would be a mean value plus or minus 1x, 2x or 3x your standard deviation. In this article we will just use `[bound]` as the limit to use.

### Control Charts Detection Rules With Table Calcs ###

For a quick refresher on table calcs basics, head over to our article ["Basic Table Calcs"]({{site.url}}/calcs/2014/03/04/basic-table-calcs.html), or go to Tableau's very own [on-demand videos].

#### n Consecutive Increases / Decreases ####

This is a common rule for control charts: figure out when we have a streak of increases or decreases. When we go past 7, 8 or 9, we may have found an "assignable" cause, meaning we are out of the normal process conditions.

We'll start first with a table calc to find, say, the 3rd consecutive increase. The following paragraph will show how to identify all three points that participated.

##### Find points starting at the n<sup>th</sup> #####

![nConsecutiveIncreases]({{ site.url }}/assets/controlchart_increase3_lastpoints.png)

```
index() >= [n] and window_sum(
    iif( sum(Sales) > lookup( sum(Sales), -1 ), 1, 0 )
    , -[n]+1, 0) = [n]
```

Let's inspect this table calc a little bit.

`sum(Sales) > lookup( sum(Sales), -1 )` tells us if a particular point is above the previous one. So far so good.

The `window_sum` that wraps it is looking back from n-1 places up to the current place, therefore the window is n points wide. The window_sum sums up the 1's we get for each point that matches our criteria (point is an increase). Therefore, if that sum amounts to `n`, all points were an increase. Now we know that we are at the n<sup>th</sup> point or beyond in a streak of increases.

We want to make sure we only get `T` and `F` with this calc, which is why we guard nulls with the `index() >= [n]` up front. Indeed, the window_sum would return null if the window was invalid.

##### Find all points in the streak #####

Now if you want to find all the points that *participate* in a streak of increases, as illustrated below,

![nConsecutiveIncreases]({{ site.url }}/assets/controlchart_increase3.png)

we'll have to wrap our original formula with a secondary table calc, that will check if any of the n points ahead are an n<sup>th</sup> consecutive increase.

Our table calc now looks like this:

```
window_max(

    iif( index()>[n] and window_sum(
            iif( sum(Sales) > lookup( sum(Sales), -1 ), 1, 0 )
            , -[n]+1, 0) = [n]
        , 1, 0 )

, 0, [n]-1 ) = 1
```

Its domain is \[`T`,`F`\]:

| Value | Meaning |
|-------|---------|
| T     | This point participates in an p-long streak of increases, p>=n |
| F     | This point does not participare in a an n-long streak of increases |


#### n Consecutive Outside Bounds ####

This another common rule for control charts. We want to know when n points are beyond a particular limit, e.g. 1 point above the centerline + 3 x standard deviation, or 8 consecutive points on the same side of the centerline.

You can derive a lot of additional control chart rules simply by taking our table calc above and replacing
```
sum(Sales) > lookup( sum(Sales), -1 )
```
with another expression, for example:
```
sum(Sales) > [bound]
```
to look for n consecutive points above a particular boundary.

The resulting calc would be:

```
window_max(

    iif( index()>[n] and window_sum(
            iif( sum(Sales) > [bound], 1, 0 )
            , -[n]+1, 0) = [n]
        , 1, 0 )

, 0, [n]-1 ) = 1
```

#### m out of n Consecutive Outside Bounds ####

On to something that will expand our arsenal of table calcs for control charts.

In the screenshot below we're looking for windows where 2 out of 3 points are above the boundary:

![nConsecutiveIncreases]({{ site.url }}/assets/controlchart_boundary_n_out_of_m.png)

With this exercise, we get to a pretty general calculation that can handle a lot of cases.
It checks within a window that is `n` long if at least `m` points match a criteria. This gives us a 0 or 1 value.
Then we multiply this by 2 if the current point matches the criteria.

See below:

```
window_max(

    iif( index()>[n] and window_sum(
            iif( sum(Sales) > [boundary], 1, 0 )
            , -[n]+1, 0) >= [m]
        , 1, 0 )

, 0, [n]-1 )

// mutiplying by 2 if this point is above boundary
* iif( sum(Sales) > [boundary], 2, 1 )
```

We get the following domain for this calculated field:

| Value | Meaning | Color in our example |
|-------|---------|----------------------|
| 0     | This point does not match the m out of n rule | Grey |
| 1     | This point matches the m out of n rule | Orange |
| 2     | This point matches the m out of n rule AND matches the criteria | Red  |


[Control Charts]: http://en.wikipedia.org/wiki/Control_charts
[on-demand videos]: http://www.tableausoftware.com/learn/training