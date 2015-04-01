class Listing < ActiveRecord::Base
  require 'net/http'
  require 'uri'
  require 'json'
  require 'nokogiri'
  require 'open-uri'
  require 'mechanize'
  
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

    page = agent.get("https://www.couchsurfing.com/groups/14")

    page.links.each do |link|
      if link.href.include?("/groups/14/threads/")
        unless link.href.include?("/groups/14/threads/new")
          new_page = link.click
          
          source = "cs"
          url = "https://www.couchsurfing.com" + link.href

          t.datetime "published_at"
          t.text     "title"
          t.text     "content"
          t.string   "name"
          t.string   "profile_url"
          
          new_page.search(".comment--initial .comment").search(".comment__recipient").text # first and last name
          new_page.search(".comment--initial .comment").search(".comment__recipient").search("a")[0]["href"] # link to profile
          new_page.search(".comment--initial .comment").search(".card__location").text # location
          new_page.search(".comment--initial .comment").search(".comment__text").text # content
          new_page.search(".comment--initial .comment").search(".comment__date").text # date
          new_page.search("island__super-title").text # title
        end
      end
    end
    
    next_page = "https://www.couchsurfing.com/groups/14/page/2"
    
    link_group
  end
  
end
