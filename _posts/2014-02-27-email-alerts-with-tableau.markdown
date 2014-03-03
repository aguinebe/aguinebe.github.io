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

1. **Configure Tableau Server to accept requests for trusted tickets**. This does two things for you. First, the script will not need to know any password, it will simply request trusted tickets to perform its work. Second, ans this optional, it enables the emailing script to impersonate the recipient of each email instead of using filters to filter the relevant information. This impersonation is necessary if you have row-level security implemented in published datasources.

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


## Setting up ruby ##

<div markdown="1" class="todo">

<p class="todotitle">TODO</p>
1. Head over to [Ruby Installer] and download the ruby installer. As I am writing this the latest version is ruby 1.9.3.
1. As the name indicates, this is an installer, specially for Windows. Simply run the .exe, click through the setup wizard.
1. Open a command prompt, type `irb`, which is the interactive ruby shell
1. Type `print 'Hello, world'`
1. You have written your first line of ruby! Close this command prompt.

</div>

![Testing ruby]({{ site.url }}/assets/testing_ruby.png)

## Setting up an email server ##

If you already have an SMTP server that you can use, skip this test. Otherwise:

<div markdown="1" class="todo">

<p class="todotitle">TODO</p>
1. Install an SMTP server. I like [hMailServer] but any mail server will work.

</div>

## Enable trusted tickets ##

This step enables the script to run reports on behalf of the administrator, and if needed, on behalf of recipients too.

To enable trusted tickets,

<div markdown="1" class="todo">

<p class="todotitle">TODO</p>
1. Figure out the IP address of the machine that is going to run the alerting script. You can do this with a command prompt and the `ipconfig` command.
1. Follow the instructions on how to [setup trusted tickets] on the Tableau online documentation.

</div>

## Download the script and test it! ##

We're ready to test this!

<div markdown="1" class="todo">

<p class="todotitle">TODO</p>
1. Download the [tabalert.rb]({{ site.url }}/assets/tabalert.rb) script.
1. To test it out, open a command prompt, and type:
</div>

    ruby tabalert.rb inventory_alerts Default 1=1 manager

Let's review the parameters:

| Parameter    | Value in our Example | Purpose |
|--------------|----------------------|---------|
| `workbookname` | inventory_alerts     | The name of the workbook as published on Tableau Server |
| `sitename`     | Default              | The site you published your workbook to                 |
| `additional url string` | 1=1         | This will be added to the URL when requesting both the list of recipients, and the content to be sent out. Use this to pass, for example, a parameter value. Or leave it at 1=1 which does nothing. |
| `trusted or field to filter` | manager | Indicate here `trusted` if you want to customize the content sheet by impersonating the recipient, or a field name to place a filter on this field and pass the name of the recipient. In our example, the `manager` field will be filtered using values found in the first column of the `recipients` sheet. |

[Tableau Software]: http://www.tableausoftware.com
[Business Intelligence]: http://en.wikipedia.org/wiki/Business_intelligence
[alerting capabilities for system health issues]: http://onlinehelp.tableausoftware.com/current/server/en-us/help.htm#email.htm
[Subscriptions]: http://www.tableausoftware.com/about/blog/2013/3/subscriptions-reports-or-worksheets-21635
[Ruby Installer]: http://rubyinstaller.org/
[hMailServer]: http://www.hmailserver.com/
[setup trusted tickets]: http://onlinehelp.tableausoftware.com/current/server/en-us/trusted_auth_trustIP.htm