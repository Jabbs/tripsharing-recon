class Listing < ActiveRecord::Base
  require 'net/http'
  require 'uri'
  require 'json'
  require 'nokogiri'
  require 'open-uri'
  require 'mechanize'
  
  geocoded_by :location
  after_validation :geocode
  
  validates :url, presence: true, uniqueness: true
  
  def self.get_lonelyplanet_trips
    lp_trips = []
    url = "https://www.lonelyplanet.com/thorntree/forums/travel-companions.atom"
    xml = Nokogiri::XML(open(url))

    xml.search('entry').each do |entry|
      lp_entry = {}
    	lp_entry["id"] = entry.search('id').text
    	lp_entry["published"] = entry.search('published').text
    	lp_entry["updated"] = entry.search('updated').text
    	lp_entry["url"] = entry.search('url').text
    	lp_entry["title"] = entry.search('title').text
    	lp_entry["content"] = entry.search('content').text
    	lp_entry["author"] = entry.search('author').search('name').text
    	lp_trips << lp_entry
    end
    lp_trips
  end
  
  def self.parse_couch_surfing
    agent = Mechanize.new
    url = "https://www.couchsurfing.com/users/sign_in"
    agent.get(url)
    form = agent.page.forms.first
    form['user[login]'] = "jerrybarn10@gmail.com"
    form['user[password]'] = "3035jerry"
    form.submit



    100.times do |n|
      url_first = "https://www.couchsurfing.com/groups/14/page/"
      page_number = (n + 160).to_s
      url = url_first + page_number
      page = agent.get(url)
      
      page.links.each do |link|
        if link.href.include?("/groups/14/threads/")
          unless link.href.include?("/groups/14/threads/new")
            url = "https://www.couchsurfing.com" + link.href
            unless Listing.find_by_url(url).present?
              new_page = link.click
              source = "cs"
              name = new_page.search(".comment--initial .comment").search(".comment__recipient").text # first and last name
              profile_url = new_page.search(".comment--initial .comment").search(".comment__recipient").search("a")[0]["href"] # link to profile
              location = new_page.search(".comment--initial .comment").search(".card__location").text # location
              content = new_page.search(".comment--initial .comment").search(".comment__text").text # content
              unparsed_date = new_page.search(".comment--initial .comment").search(".comment__date").text # date
              # published_at = DateTime.parse(unparsed_date)
              title = new_page.search("island__super-title").text # title
              Rails.logger.info url
              listing = Listing.create(source: source, url: url, name: name, profile_url: profile_url, location: location,
                             content: content, unparsed_date: unparsed_date, title: title)
              if listing.present?
                Rails.logger.info "Listing created: id: #{listing.id}, Location: #{listing.location}, lat: #{listing.latitude} long: #{listing.longitude}"
                sleep 10
              end
            end
            
          end
        end
      end
      
    end
    
    
  end
  
end
