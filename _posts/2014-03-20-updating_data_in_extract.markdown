---
layout: post
title:  "Refreshing Large Extracts Faster"
date:   2014-03-20 14:48:00
author: Alexis Guinebertiere
categories: data
excerpt: How does this work again?
published: yes
---

### Slow, slow, quick, quick ###

Extracts are easy to create, and they perform beautifully. To this day is still baffles me that for $2k, you can buy a piece of software that will turn any data into a columnar format that lets you slice and dice hundred million rows at the speed of thought!

On the down side, extracts can take some time to create. Tableau Desktop extracts at the ballpark rate of 1M rows per minute, so if you have 1B rows of data, this translates to 16 hours, which is not unheard of. This becomes problematic if your data changes often.

So naturally, you start thinking... I just have a few lines of data that changed in my original data source. Can I update the extract, and only update those lines that changed? Unfortunately, no. You cannot, at least at this point, update data in an extract or even remove data. You simply refresh the entire extract, which means all the data is read from the original datasource again, and the extract is recreated.

### The Workaround ###

The idea to work around this is a two step process:
- First, create an extract with data that is immutable. Probably data that is older than, say, 14 days
- Second, duplicate this extract, and add to it the recent data that is missing. You obtain a complete, up-to-date extract

#### 1 - Creating the immutable extract ####

Creating an extract in itself is very straightforward. Point Tableau Desktop to the data source, ass a calculation, remove and rename fields, extract. Done.

In our case, we want to design an extract that will initially pull the old, immutable data, and subsequently extract the newer data incrementally.

To do so, we cannot simply put a filter using a date calculation like `datediff( 'days', today(), [Date] ) > 14`. While this would correctly extract only the old immutable data, this design fails to pull new data when you refresh the extract.

To extract only old data the first time, and all data thereafter, we'll have to design a filter that excludes recent data the first time we refresh, but does not exclude recent data thereafter.

This is where we'll have to borrow from the Tableau Ninja bag of tricks.

Let's create a calculated field:`if datediff( 'days', today(), [Date] ) > 14 then datetrunc( 'minute', now() ) end`

For recent rows of data, this field will take the current date and time, rounded to the minute. For older rows, this will be null.

When extracting, we can now use this field, and exclude the only non-null value that it takes, e.g. `2014-02-24 12:20`. As we extract this data the first time, the recent lines are excluded. But by the time we refresh this extract again, time will have elapsed, and our exclusion filter will no longer exclude any lines of data.

Here is the resulting workbook. Use the date offset to bring all dates closer to today.

<p class='hyperlink' markdown='1'>
![tableau workbook icon]({{ site.url }}/assets/tableau_workbook.png)
[incremental_update.twbx]({{ site.url }}/assets/incremental_update.twbx)
</p>

#### 2 - Adding data to create the up-to-date extract  ####

The following script will connect to a Tableau Server deployed on `localhost`, on a site called `test`, with a username `admin` and password `admin`.

The `tabcmd login` will, uh, log us in. The `tabcmd get` and subsequent `tabcmd publish` are here to simply duplicate the immutable extract, and overwrite the `up_to_date_data` extract. At this point the `up_to_date_data` is an exact copy of the immutable data. Finally, the `tabcmd refreshextracts` will trigger a refresh of the `up_to_date_data` data source. Since it was designed to be an incremental update, it only pulls the missing data, according to the field `Order Date`.


```
tabcmd login -s http://localhost -t test -u admin -p admin
tabcmd get "/datasources/immutable_data.tdsx" --filename up_to_date_data.tdsx
tabcmd publish up_to_date_data.tdsx --overwrite
tabcmd refreshextracts --datasource up_to_date_data
tabcmd logout
```
