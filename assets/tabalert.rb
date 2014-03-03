require 'net/http'
require 'uri'
require 'json'
require 'net/smtp'

puts "


###########################################
#                                         #
# TABALERT2!                              #
# Alexis Guinebertiere - Tableau Software #
# October 2013 - February 2014            #
#                                         #
###########################################

This program sends email alerts based on Tableau workbooks!

Usage:

	ruby tabalert.rb <workbookname> <sitename> <additional URL string> <trusted_or_filter_on>

<workbookname> indicates the workbook that contains the alert	
The list of potential recipients should be in the 'recipients' view.
The content to be sent out should be in the 'content' view.

<Additional URL string>: place here some parameters or filters to pass to the workbook, e.g. '?threshold=20'

<trusted_or_filter_on>: put here the name of a field to filter on on the content page, or trusted if you want to use trusted tickets instead

"

#
# First, getting a ticket to read list of potential recipients
#

if ARGV.size > 0
	workbook = ARGV[0]
else
	workbook = "alerts"
end

if ARGV.size > 1
	sitename = ARGV[1]
else
	sitename = "Default"
end

if ARGV.size > 2
	URLsuffix = ARGV[2]
else
	URLsuffix = ""
end

if ARGV.size > 3
	trusted_or_filter_on = ARGV[3]
else
	trusted_or_filter_on = "trusted"
end

puts workbook + "-" + sitename + "-" + URLsuffix + "-" + trusted_or_filter_on

puts "Asking for an administrator ticket"

tabserver = "localhost"

post_data = {
	  "username" => "admin",
	  "target_site" => sitename,
	  "client_ip" => "127.0.0.1"
	}

ticket = "-1"

tried = 1

while ticket=="-1" and tried>0
	response = Net::HTTP.post_form(URI.parse("http://#{tabserver}/trusted"), post_data)
	ticket = response.body
	tried = tried - 1
	puts "Ticket is " + ticket
end

if ticket == "-1" then
	puts "Couldn't get ticket"
else

	#
	# Now getting list of potential recipients
	#

	redeem = Net::HTTP.get_response(URI.parse("http://#{tabserver}/trusted/#{ticket}/t/#{sitename}/views/#{workbook}/recipients.csv?#{URLsuffix}") )
	cookie = { "Cookie" => redeem.response['set-cookie'].split('; ')[0] }

	http = Net::HTTP.new( tabserver, 80 )
	request = Net::HTTP::Get.new( redeem[ "location" ], cookie )
	recipients = http.request( request )

	rows = recipients.body.gsub( "\r","").split( "\n" )
	fields = rows[0].split( "," )

	# puts( "Fields in the recipients view are:" )
	# fields.each do |f| puts( f ) end

	table = []

	for r in 1..(rows.size-1) do
		row = rows[r].split( "," )
		row = fields.zip(row).flatten
		table << Hash[ *row ]
	end

	#
	# Going through recipients
	#

	table.each do |r|
		#puts( "Recipient is " + r.to_json )

		location = ""

		if trusted_or_filter_on == "trusted" then
			puts "Trusted mode"
			puts( "Asking ticket for " + r[ "First name" ] )

			post_data = {
			  "username" => r[ "Tableau account" ],
			  "target_site" => sitename,
			  "client_ip" => "127.0.0.1"
			}

			response = Net::HTTP.post_form(URI.parse("http://#{tabserver}/trusted"), post_data)
			ticket = response.body

			redeem = Net::HTTP.get_response(URI.parse("http://#{tabserver}/trusted/#{ticket}/t/#{sitename}/views/#{workbook}/content.csv?#{URLsuffix}") )
			cookie = { "Cookie" => redeem.response['set-cookie'].split('; ')[0] }

			http = Net::HTTP.new( tabserver, 80 )
			request = Net::HTTP::Get.new( redeem[ "location" ], cookie )
			content = http.request( request )

			location = redeem[ "location" ]

		else # trusted or ticket
			account = r[ "Tableau account" ]
			#puts( "Filtering on " + trusted_or_filter_on + "=" + r[ "Tableau account" ] )

			post_data = {
			  "username" => "admin",
			  "target_site" => sitename,
			  "client_ip" => "127.0.0.1"
			}

			response = Net::HTTP.post_form(URI.parse("http://#{tabserver}/trusted"), post_data)
			ticket = response.body

			redeem = Net::HTTP.get_response(URI.parse("http://#{tabserver}/trusted/#{ticket}/t/#{sitename}/views/#{workbook}/content.csv?#{trusted_or_filter_on}=#{account}&#{URLsuffix}") )
			cookie = { "Cookie" => redeem.response['set-cookie'].split('; ')[0] }

			http = Net::HTTP.new( tabserver, 80 )
			request = Net::HTTP::Get.new( redeem[ "location" ], cookie )
			content = http.request( request )

			#puts redeem[ "location" ]

			location = redeem[ "location" ]

			#puts "Content for " + r[ "Tableau account" ] + " is:"
			#puts content

		end

		# checking how many lines the csv version of the content has
		nblines = content.body.split( "\n" ).size

		if nblines > 1
			puts( "Sending email to " + r[ "First name" ] )

			http = Net::HTTP.new( tabserver, 80 )
			request = Net::HTTP::Get.new( location.gsub( ".csv", ".pdf" ), cookie )
			pdf = http.request( request )

			http = Net::HTTP.new( tabserver, 80 )
			request = Net::HTTP::Get.new( location.gsub( ".csv", ".png" ), cookie )
			png = http.request( request )

			marker = "435782364578934"
			emailaddr = r[ "Email" ]
			firstname = r[ "First name" ]

			encodedimage = [png.body].pack("m")
			encodedcontent = [pdf.body].pack("m")

			Net::SMTP.start( 'localhost' ) do |smtp|
				message = <<MESSAGE_END
From: Tableau Alert <admin@tableau.com>
To: #{firstname} <#{emailaddr}>
Subject: Tableau alert for #{firstname}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}

--#{marker}
Content-Type: text/html

<p/>
<img src="image.png">

--#{marker}
MESSAGE_END

	attachment1 =<<EOF
Content-Type: application/pdf; name=alert.pdf
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="alert.pdf"

#{encodedcontent}
--#{marker}--
EOF

	attachment2 =<<EOF
Content-Type: image/png; name=image.png
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename=image.png

#{encodedimage}
--#{marker}
EOF

				smtp.send_message message + attachment2 + attachment1, 'admin@tableau.com', r[ "Email" ]
			end
		else
			puts( "No need to send email to " + r[ "First name" ] )
		end
	end
end


