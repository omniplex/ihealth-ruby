# This gem abstracts F5s iHealth API and allows.
# This gem will allow you to do the following:
#  * Authenticate
#  * Upload a qkview
#  * Get list of IDs of qkviews already uploaded
#  * Get meta data about a particular ID already uploaded
#  * Get the full heuristic report for an ID already uploaded
#
# Author:: Dave B. Greene (omniplex@omniplex.net)
# Copyright:: Copyright (c) 2012 Dave Greene
# License:: GPL V3
 


require 'net/http'
require 'net/https'
require 'uri'
require 'json'

# This class provides the interface to F5s iHealth API system
# and requires that you have an active account with F5.
class Ihealth

  # Sets the default "User Agent" that will be passed to identify the application
  # Please Change the User Agent to be descriptive for your organization.
  USER_AGENT = "Ruby iHealth Gem/2.3.0"

  # Creates the initial connection by performaing authentication
  def initialize username, password, proxyserver = nil, proxyport = nil, proxyuser = nil, proxypass = nil
    @username = username
    @password = password
    @proxyserver = proxyserver
    @proxyport = proxyport
    @proxyuser = proxyuser
    @proxypass = proxypass
    @authenticated = false
    @IHEALTHBASE= "https://ihealth-api.f5.com/qkview-analyzer/api/"
    
    # Try and authenticate
    authenticate
  end
  
  # Uploads a file to iHealth for heuristic processing
  def upload filepath
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews?retain=true")
    headers = {'User Agent' => USER_AGENT, 'Transfer-Encoding' => 'chunked', 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ihealthrequest = Net::HTTP::Post.new(url.path + "?" + url.query, headers)
    ihealthrequest.content_type = 'application/gzip'
    ihealthrequest.body_stream = File.open(filepath, 'rb')
    response = ihealthclient.request(ihealthrequest)
    response.code == "303" ? (return response['location'][/[0-9]*$/,0]) : (return nil)
  end

  # Gets a list of IDs that are stored in the iHealth system after qkviews have been uploaded.
  def get_id_list format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews.#{format}")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    #ihealthclient = Net::HTTP.new(url.host, url.port)
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http| 
      http.request(httprequest)
    end
    response.code != "200" ? (raise "We received #{response.code}") : (t_ids = JSON.parse(response.body))
    return t_ids['qvList']['id']
  end
  
  # Gets meta data for a particular ID where a qkview has already been upladed to the iHealth system.
  def get_meta_for_id qid, format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}.#{format}")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    #ihealthclient = Net::HTTP.new(url.host, url.port)
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    response.code != "200" ? (return nil) : (t_meta = JSON.parse(response.body))
  end
  
  # Gets the diagnostic data for an ID where a qkview has already been uploaded to the iHealth system.
  # Default output format is JSON.
  def get_diagnostics qid, format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}/diagnostics.#{format}?set=hit&audience=all")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    #ihealthclient = Net::HTTP.new(url.host, url.port)
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    response.code != "200" ? (return nil) : (t_diagnostic = JSON.parse(response.body))
    return t_diagnostic['qvDiagnosticOutput'] 
  end
  
  # Deletes a qkview from the system.
  def delete qid
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port, @proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Delete.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    return response.code
  end

  def delete_all
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port, @proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Delete.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    return response.code
  end

  # This method returns the list of available commands to execute against a given diagnostic
  # TODO: Fix 
  def get_command_list qid, format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}/commands.#{format}")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    response.code != "200" ? (return nil) : (t_commands = JSON.parse(response.body))
    return t_commands['qvCommandList'] 
  end

  # Get the result from a single command
  def get_command_output qid, command, format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}/command.#{format}")
    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    response.code != "200" ? (return nil) : (t_commands = JSON.parse(response.body))
    return t_commands['qvCommandOutputList'] 
  end

  def get_commands_output qid, commands, format = "json"
    authenticate if !@authenticated
    url = URI("#{@IHEALTHBASE}qkviews/#{qid}/command.#{format}")
    respone = make_request url
    # headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    # @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    # ihealthclient.use_ssl = true
    # ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # httprequest = Net::HTTP::Get.new(url.path + "?" + url.query, headers)
    # httprequest.content_type = 'application/xml'
    # response = ihealthclient.start do |http|
    #   http.request(httprequest)
    # end
    response.code != "200" ? (return nil) : (t_commands = JSON.parse(response.body))
    return t_commands['qvCommandOutputList'] 
  end
  
  

# no reason to call authenticate directly
  private 
  
  # Performs authentication and saves the cookie information
  def authenticate
    # probably should abstract this out more.
    url = URI('https://login.f5.com/resource/loginAction.jsp')
    headers = {'User Agent' => USER_AGENT }
    #ihealthclient = Net::HTTP.new(url.host, url.port)
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
      ihealthclient.use_ssl = true
      ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
      httprequest = Net::HTTP::Post.new(url.path, headers)
      httprequest.set_form_data('userid' => @username, 'passwd' => @password)
      httprequest.content_type = 'application/x-www-form-urlencoded'

      response = ihealthclient.start do |http|
        http.request(httprequest)
      end

    # All reponse codes seem to be redirects. Either back to the login page or the account page
    # so we check for the account page.
    if (response['location'] == 'https://login.f5.com/myaccount/index.jsp')
      @authenticated = true
      all_cookies = response.get_fields('set-cookie')
      cookies_array = Array.new
        all_cookies.each { | cookie |
        cookies_array.push(cookie.split('; ')[0])
        }
      @cookies = cookies_array.join('; ')
    end
  end
  
  # TODO: Create method to handle web requests and return data so everything isn't repeated
  # Below works if a GET request. Need to modify for all types.
  def make_request url
    authenticate if !@authenticated

    headers = {'User Agent' => USER_AGENT, 'Cookie' => @cookies }
    @proxyserver.nil? ? (ihealthclient = Net::HTTP::new(url.host, url.port)) : (ihealthclient = Net::HTTP::new(url.host, url.port,@proxyserver, @proxyport, @proxyuser, @proxypass))
    ihealthclient.use_ssl = true
    ihealthclient.verify_mode = OpenSSL::SSL::VERIFY_NONE
    httprequest = Net::HTTP::Get.new(url.path + "?" + url.query, headers)
    httprequest.content_type = 'application/xml'
    response = ihealthclient.start do |http|
      http.request(httprequest)
    end
    return response
    
  end


end



