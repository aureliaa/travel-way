require "json"
require "http"
require "optparse"


# Place holders for Yelp Fusion's OAuth 2.0 credentials. Grab them
# from https://www.yelp.com/developers/v3/manage_app

class FetchActivitiesService
  # Constants, do not change these
  API_HOST = "https://api.yelp.com"
  SEARCH_PATH = "/v3/businesses/search"
  BUSINESS_PATH = "/v3/businesses/"  # trailing / because we append the business id to the path
  TOKEN_PATH = "/oauth2/token"
  GRANT_TYPE = "client_credentials"


  DEFAULT_BUSINESS_ID = "yelp-san-francisco"
  DEFAULT_TERM = "dinner"
  DEFAULT_LOCATION = "San Francisco, CA"
  SEARCH_LIMIT = 4

  CLIENT_ID = ENV['YELP_ID']
  CLIENT_SECRET = ENV['YELP_SECRET']

  def initialize(term, location)
    @url = "#{API_HOST}#{SEARCH_PATH}"
    @params = {
    categories: term,
    location: location,
    sort_by: 'rating',
    radius: 30000,
    limit: SEARCH_LIMIT
  }
  end

  def call
    response = HTTP.auth(bearer_token).get(@url, params: @params)
    response.parse['businesses']
    response.parse['businesses'].map {|business| business.slice('id', 'name', 'location', 'display_phone', 'image_url', 'description', 'coordinates') }
  end


  private

  def bearer_token
    # Put the url together
    url = "#{API_HOST}#{TOKEN_PATH}"

    raise "Please set your CLIENT_ID" if CLIENT_ID.nil?
    raise "Please set your CLIENT_SECRET" if CLIENT_SECRET.nil?

    # Build our params hash
    params = {
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: GRANT_TYPE
    }


    response = HTTP.post(url, params: params)
    parsed = response.parse

    "#{parsed['token_type']} #{parsed['access_token']}"
  end

end


# Make a request to the Fusion API token endpoint to get the access token.
#
# host - the API's host
# path - the oauth2 token path
#
# Examples
#
#   bearer_token
#   # => "Bearer some_fake_access_token"
#
# Returns your access token




# Make a request to the Fusion search endpoint. Full documentation is online at:
# https://www.yelp.com/developers/documentation/v3/business_search
#
# term - search term used to find businesses
# location - what geographic location the search should happen
#
# Examples
#
#   search("burrito", "san francisco")
#   # => {
#          "total": 1000000,
#          "businesses": [
#            "name": "El Farolito"
#            ...
#          ]
#        }
#
#   search("sea food", "Seattle")
#   # => {
#          "total": 1432,
#          "businesses": [
#            "name": "Taylor Shellfish Farms"
#            ...
#          ]
#        }
#
# Returns a parsed json object of the request


# Look up a business by a given business id. Full documentation is online at:
# https://www.yelp.com/developers/documentation/v3/business
#
# business_id - a string business id
#
# Examples
#
#   business("yelp-san-francisco")
#   # => {
#          "name": "Yelp",
#          "id": "yelp-san-francisco"
#          ...
#        }
#
# Returns a parsed json object of the request



options = {}
OptionParser.new do |opts|
  opts.banner = "Example usage: ruby sample.rb (search|lookup) [options]"

  opts.on("-tTERM", "--term=TERM", "Search term (for search)") do |term|
    options[:term] = term
  end

  opts.on("-lLOCATION", "--location=LOCATION", "Search location (for search)") do |location|
    options[:location] = location
  end

  opts.on("-bBUSINESS_ID", "--business-id=BUSINESS_ID", "Business id (for lookup)") do |id|
    options[:business_id] = id
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!


command = ARGV


case command.first
when "search"
  term = options.fetch(:term, DEFAULT_TERM)
  location = options.fetch(:location, DEFAULT_LOCATION)

  raise "business_id is not a valid parameter for searching" if options.key?(:business_id)

  response = search(term, location)

  puts "Found #{response["total"]} businesses. Listing #{SEARCH_LIMIT}:"
  response["businesses"].each {|biz| puts biz["name"]}
when "lookup"
  business_id = options.fetch(:business_id, DEFAULT_BUSINESS_ID)


  raise "term is not a valid parameter for lookup" if options.key?(:term)
  raise "location is not a valid parameter for lookup" if options.key?(:lookup)

  response = business(business_id)

  puts "Found business with id #{business_id}:"
  puts JSON.pretty_generate(response)
else
  puts "Please specify a command: search or lookup"
end
