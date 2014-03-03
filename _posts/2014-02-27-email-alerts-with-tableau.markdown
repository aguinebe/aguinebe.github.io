---
layout: post
title:  "Email alerts"
tagline:	"with Tableau"
image:	2014-02-28_13-23-19.png
caption: Alert! Inventory for Widget A is 25, which is below the reorder level of 30! Click here for the full report.
date:   2014-02-27 12:54:56
categories: extending
excerpt: Tableau Software does not provide alerting capabilities. In this post we'll see how to build alerts nevertheless.
---

## What is alerting? ##

 Alerting is a common [Business Intelligence] feature. Instead of refreshing a dashboard or report regularly to see if something went wrong in your business, you would receive an email alert automatically. Some call this managing by exception.

 The event that triggers the alert could be a metric crossing a threshold, such as an inventory level dipping below the reorder level. In this example, the email subject would look like the following:

 `"Alert! Inventory for Widget A is 25, which is below the reorder level of 30!"`

 The content of the email would be a report that shows the metric in context. In our example this could possibly be the inventory level trend.

## Does Tableau offer alerting? ##

While it does provide system administrator [alerting capabilities for system health issues], Tableau 8.1 does not provide business user alerting capabilities.

That was the bad news.

The good news is that Tableau is actually quite gifted at both implementing business rules and producing static content such as images and PDFs.

So what's missing? Mainly the emailing mechanism. What we used to call "mail merge" in Microsoft Word in 1995: take a list of recipients, take a template email, and merge them to send out emails.

## How we are going to implement alerts ##

To close this gap and turn Tableau Server into an alerting server, here are the overall tasks:

1. **Create a workbook that monitors inventory levels**. A tab will identify the managers that need to be alerted, and another tab will have the content that needs to be emailed out

1. **Install the ruby development environment**. Luckily there are one-click install packages out there.

1. **Configure Tableau Server to accept requests for trusted tickets**. This enables the emailing script to impersonate the recipient of each email instead of using filters to filter the relevant information. This step is necessary if you have row-level security implemented in published datasources.

1. **Install an SMTP mail server** if you don't already have one 

1. **Test it!** We'll run the script on the sample workbook I provide here, and see the emails go out!

##Sample data and workbook##

To help us with this exercise, I put together a (very) simple dataset and workbook. The download links are below in the TODO list. The dataset is stored in an excel spreadsheet, one table per tab, and looks like this:

inventory

![product inventory]({{ site.url }}/assets/product_inventory.png)

reorder level

![product inventory]({{ site.url }}/assets/product_reorder.png)

managers

![product inventory]({{ site.url }}/assets/product_manager.png)

As you can see, `plates` are managed by both `melanie` and `christophe`. Other products are split between these two managers.

The workbook contains two tabs. The first tab shows the products for each manager. All three tables have been joined together. A T/F calculated field `on alert` indicates if the product is on alert. It is defined as `[inventory] <= [reorder_level]`.

![product inventory]({{ site.url }}/assets/products_on_alert.png)

The second tab shows the managers we need to alert. We simply added the `on alert` field as a filter that keeps `true`.

![product inventory]({{ site.url }}/assets/managers_on_alert.png)


## Setting up the workbook and publishing to Tableau Server ##

<div markdown="1" class="todo">

<p class="todotitle">TODO</p>
1. Download the [excel spreadsheet]({{ site.url }}/assets/inventory.xlsx), save it to a location accessible by your server, e.g. your desktop if Tableau Server is installed locally, or a shared folder if Tableau Server is on a separate machine.

1. Download the [inventory alerts workbook]({{ site.url }}/assets/inventory_alerts.twb)

1. Open the workbook, edit the data source connection, point it to your copy of the spreadsheet on your desktop - use the shared folder URI if your are using a shared folder, e.g. `\\sharedfileserver\folder\inventory.xlsx`

1. Save and publish to Tableau Server. Make sure to uncheck the `Include External Files` on the publish dialog. This ensures that the workbook is still connecting to the original spreadsheet, and not static a copy on the server.

</div>

## Conventions for the workbook## 

The workbook should have at least two sheets:

| Sheet          | Purpose  |
| ---------------|----------|
| `recipients`   | The recipients sheet should contain two columns. The first one has the name of the recipient, the second one has his/her email address. The heading of the column does not matter. |
| `content`      | The content sheet has the content that will be emailed. It should optionnaly have a field that we can use to filter, e.g. in our example workbook the `manager` field can be used to filter and customize this sheet for a particular recipient. As an alternative to the filter field, the ruby script can use trusted ticket to sign into Tableau Server and impersonate the recipients.  |


[Tableau Software]: http://www.tableausoftware.com
[Business Intelligence]: http://en.wikipedia.org/wiki/Business_intelligence
[alerting capabilities for system health issues]: http://onlinehelp.tableausoftware.com/current/server/en-us/help.htm#email.htm
[Subscriptions]: http://www.tableausoftware.com/about/blog/2013/3/subscriptions-reports-or-worksheets-21635