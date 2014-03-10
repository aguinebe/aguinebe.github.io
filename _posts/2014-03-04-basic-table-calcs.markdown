---
layout: post
title:  "Basic Table Calcs"
date:   2014-03-04 14:48:00
author: Alexis Guinebertiere
categories: calcs
excerpt: How does this work again?
published: true
---

This is a brief introduction to table calcs.

### Getting Started With Quick Table Calcs ###

Go ahead and open Tableau, and use Superstore. Double click on `Sales`. Double click on `Category`. Sort descending. Click on the `Sales` pill, and choose `Quick Table Calc`, `Running Total`. Congratulations! You have created your first pareto chart:

![Quick Table Calc]({{ site.url }}/assets/table_calcs_quick.png)

For more information on table calcs, I recommend Tableau's very own [on-demand videos].

### Table Calcs Cheat Sheet ###

Now let's dive into table calcs and how they are constructed with calculated fields.

Let's take a simple `measure`, over a 8 periods.
In the following, all table calcs are calculated from left to right, also known as computed using `Table (Across)`. This is the default way to go through the data, although you can instruct Tableau to go through the data `Table (Down)` as well.

The first line shows our data with `sum(measure)`, that is 2, 4, 7, 7, etc.

The following lines show some of the basic table calculations you can perform on this data. The first table calcs `index()`, `size()`, `first()` and `last()` do not use the data itself, they are simply returning information about the current location.

![Basic Calcs]({{ site.url }}/assets/table_calcs_basic.png)
[on-demand videos]: http://www.tableausoftware.com/learn/training