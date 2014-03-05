---
layout: post
title:  "Understanding the Table Calcs Dialogs"
date:   2014-03-05 14:48:00
author: Alexis Guinebertiere
categories: calcs
excerpt: How does this work again?
published: true
---

### The joy of table calcs ##

Ah, the joy of table calcs!

It provides great satisfaction, but to be honest it also leaves somewhat of a bad after-taste, when, after trying every permutation of addressing and partitionning fields possible, you finally stumble on it. The table calc finally works! You're not sure why and how, but it works, so you just move on.

But what actually just happened? Let's dive in.

### The purpose of table calcs ###

The purpose of table calcs is to perform calculations on the resultset obtained from the database. Think of it as a second pass of calculations. The first pass is done by the database, for example to sum up the sales by region and by year. Next, the table calc can perform calculations such as year on year sales difference.

Table calcs can also be stacked up. So you can make a third pass on your data. Maybe you want to rank the difference in sales year on year, to figure out the regions with the biggest drop? No problem, a table calc can do it.

### How do table calcs work? ###

For a table calc to work, it needs:
- *windows*, or partitions of data within which the calculation will be executed
- a *direction* to go through the data within a window (this is the "addressing" list )
- a *calculation*, e.g. the difference between the current value and the previous, or a moving sum, or the average across that window.

Let's take some business questions, and see how table calcs can help answer them. I'll be using Superstore so you can reproduce with your own copy of Tableau.

### Example 1 : Year over Year difference in sales ###

![table_calcs_ex1]({{ site.url }}/assets/table_calcs_ex1.png)

This is an easy one. The regular "compute using" does it. On the Sales pill contextual menu, choose the following:

| Setting                 | Value      |
|-------------------------|------------|
| Quick table calculation | Difference |
| Compute using           | Order Date |

But if you want to achieve the same with the advanced dialog (remember, you want to understand how it works), go ahead and edit the table calculation, and in the calculate along drop down, choose "Advanced", and use the following:

| Setting          | Value                                |
|------------------|--------------------------------------|
| Partitioning     | All fields except Year of Order Date |
| Addressing       | Year of Order Date                   |
| Order            | Automatic                            |
| Calculation Type | Difference From                      |

It still works! The reason is that both the quick table calc and the advanced one do the same thing. A quick table calc that is computed along field X will put field X alone in the addressing, and all other fields will define the partitions.

### Example 2 : Year over Year difference in quarterly sales ###

![table_calcs_ex2]({{ site.url }}/assets/table_calcs_ex2.png)

Let's try a quick table calc:

| Setting                 | Value      |
|-------------------------|------------|
| Quick table calculation | Difference |
| Compute using           | Order Date |

Unfortunately, this doesn't cut it. See the screenshot below. It computes the Quarterly sales difference, Quarter over Quarter.

![table_calcs_ex2_quick]({{ site.url }}/assets/table_calcs_ex2_quick.png)

We need to compute Year over Year, not Quarter over Quarter.

How do we achieve this? This is where the advanced dialogs come in handy:

| Setting          | Value                                |
|------------------|--------------------------------------|
| Partitioning     | All fields except Year of Order Date |
| Addressing       | Year of Order Date                   |
| Order            | Automatic                            |
| Calculation Type | Difference From                      |

Now, our computation works. Success! But why? Let's review the partionning and addressing concepts.

### Understandting Partitionning and Addressing ###

To understand partitionning and addressing, I like to shuffle my fields around on my viz. I put all the partitionning fields first, followed by the addressing fields.

In our case, we end up with `Quarter`, `Region`, and `Year`. The order of the partitionning fields does not matter, so we could also have placed the fields in the following order: `Region`, `Quarter`, and `Year`.

We end up with the following viz:

![table_calcs_ex2_part_addr_nolines]({{ site.url }}/assets/table_calcs_ex2_part_addr_nolines.png)

Now, mentally place a vertical line to separate the partitionning fields from the addressing fields. You will now see partitions of data, or windows, defined by the vertical line on their left, and the panes that tableau draws. I have materialized both the vertical line (in red) and the windows (in blue) so you can see what I am referring to:

![table_calcs_ex2_part_addr]({{ site.url }}/assets/table_calcs_ex2_part_addr.png)

With this arrangement, Tableau is going to execute table calcs one partition at a time, and for each partition, it will compute the result for each line.

In our case, the calculation is the `sum( Sales ) - lookup( sum( Sales ), -1 )`. Let's do it manually.

- The first partition is for Q1, Central, with 4 lines of data in it
	- The first line will take $91,786 and substract null (because the lookup fails, since there is no previous line), which results in null
	- The second line takes $71,292 and substracts $91,786, which equals -$20,494
	- The third line takes $86,947 and substracts $71,292, which equals $15,655
	- The fourth line takes $123,941 and substracts $86,947, which equals $36,993

- The second partition is for Q1, East, with 4 lines of data...
	- The first line will take $127,098 and substract null (because the lookup fails, since there is no previous line), which results in null
	- etc., etc.

### Definitions ###

The **partitioning** fields define the partitions of data we'll run the calcs on. Basically how we split the cake into slices.

The **addressing** fields define how we go through each partition of data. Here we go through it using the `Year` field.

That picture you see above is the way tableau "organizes" data in memory in preparation for a table calc, but in no way does it limit the way you display it on the viz. So we can shuffle the fields around on the various shelves, and our table calc still works. Actually, we can also add and remove fields to this viz ; as long as the **addressed** fields are present, the table calc will work! Fields are automatically added / removed from the partitioning list. The addressed list is the one that "matters" and that is pinned down. Remove Year from the viz and the table calc breaks.

![table_calcs_ex2_suffled]({{ site.url }}/assets/table_calcs_ex2_suffled.png)

Added the Customer Segment in columns, and removed the Quarter, and moved the Year to the left. It still works!