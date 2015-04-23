#/usr/bin/env ruby

require 'json'
require 'shellwords'
require 'uri'
require 'net/http'

# This is used to set up CouchDB with the appropriate settings

def post (url, content)
	puts "POST #{url}"
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Post.new(uri.path)
	request.basic_auth(uri.user, uri.password)
	request.add_field('Content-Type', 'application/json')
	request.body = content.to_json
	response = http.request(request)

	response.body
end

def put (url, content)
	puts "PUTS #{url}"
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Put.new(uri.path)
	request.basic_auth(uri.user, uri.password) if uri.user and uri.password
	request.add_field('Content-Type', 'application/json')
	request.body = content.to_json
	response = http.request(request)

	response.body
end

def get(url)
	puts "GET #{url}"
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Get.new(uri.path)
	request.basic_auth(uri.user, uri.password)
	request.add_field('Content-Type', 'application/json')
	response = http.request(request)

	response.body
end

username = ENV['COUCHBASE_USERNAME']
password = ENV['COUCHBASE_PASSWORD']
dbname = ENV['COUCHBASE_DATABASE_NAME']

puts "Register Admin"
puts put("http://localhost:5984/_config/admins/#{username}", password)

puts "Create Database"
puts put("http://#{username}:#{password}@localhost:5984/#{dbname}", "")
  
secdoc = {
	"admins" => {
		"names" => [ ENV['COUCHBASE_USERNAME'] ],
		"roles" => []
	},
	"members" => {
		"names" => [ ENV['COUCHBASE_USERNAME'] ],
		"roles" => []
	}
}

puts "Create Security Docs"
puts put("http://#{username}:#{password}@localhost:5984/#{dbname}/_security", secdoc)

apiAddr = ENV['API_PORT_4567_TCP_ADDR']
apiPort = ENV['API_PORT_4567_TCP_PORT']

selfIP = JSON.parse("[" + get("http://#{apiAddr}:#{apiPort}/stack/instances/self/privateip") + "]")[0]

instanceList = JSON.parse(get("http://#{apiAddr}:#{apiPort}/stack/instances"))

instanceList.each do |instance|
	ip = JSON.parse("[" + get("http://#{apiAddr}:#{apiPort}/stack/instances/#{instance}/privateip") + "]")[0]

	if ip != selfIP

		replicate = {
			"source" => "http://#{username}:#{password}@#{ip}:5984/#{dbname}",
			"target" => "#{dbname}",
			"create_target" => true,
			"continuous" => true
		}

		puts "Replicate with #{ip}"
		puts post("http://#{username}:#{password}@localhost:5984/_replicate", replicate)
	end
end
