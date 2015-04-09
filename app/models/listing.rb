class Listing < ActiveRecord::Base
  require 'net/http'
  require 'uri'
  require 'json'
  require 'nokogiri'
  require 'open-uri'
  require 'mechanize'
  
  geocoded_by :location
  after_validation :geocode
  
  validates :url, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :profile_url, length: { maximum: 255 }
  
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
  
  def self.get_fb_accounts_from_lp
    agent = Mechanize.new
    url = "https://auth.lonelyplanet.com/"
    agent.get(url)
    form = agent.page.forms_with(id: "login_form").first
    form['user[username]'] = "Jabbs"
    form['user[password]'] = "kYNB)D78g4A,"
    form.submit
    
    fb_accounts = []
    Listing.where(source: "lp").pluck(:profile_url).each do |profile_url|
      page = agent.get(profile_url)
      fb = page.search(".facebook").last.text
      unless fb == "No facebook specified."
        fb_accounts << fb
      end
    end
    fb_accounts
  end
  
  def self.get_twitter_accounts_from_lp
    agent = Mechanize.new
    url = "https://auth.lonelyplanet.com/"
    agent.get(url)
    form = agent.page.forms_with(id: "login_form").first
    form['user[username]'] = "Jabbs"
    form['user[password]'] = "kYNB)D78g4A,"
    form.submit
    
    twitter_accounts = []
    Listing.where(source: "lp").pluck(:profile_url).each do |profile_url|
      page = agent.get(profile_url)
      twitter = page.search(".twitter").last.text
      unless twitter == "No twitter specified."
        twitter_accounts << twitter
      end
    end
    twitter_accounts
  end
  
  def self.parse_lp
    agent = Mechanize.new
    url = "https://auth.lonelyplanet.com/"
    agent.get(url)
    form = agent.page.forms_with(id: "login_form").first
    form['user[username]'] = "Jabbs"
    form['user[password]'] = "kYNB)D78g4A,"
    form.submit
    
    # 10 per page
    300.times do |n|
      url_first = "https://www.lonelyplanet.com/thorntree/forums/travel-companions?page="
      page_number = (n + 313).to_s
      url = url_first + page_number
      page = agent.get(url)
      
      page.links.each do |link|
        if link.href.present? && link.href.include?("/travel-companions/topics/")
          unless link.href.include?("/travel-companions/topics/new")
            url = "https://www.lonelyplanet.com" + link.href
            unless Listing.find_by_url(url).present?
              new_page = link.click
              source = "lp"
              if new_page.search(".user-info__username").any? && new_page.search(".user-info__username").first.search("a").any? && new_page.search(".user-info__username").any?
                name = new_page.search(".user-info__username").first.text[2..-1] # username
                profile_url = new_page.search(".user-info__username").first.search("a")[0]["href"] # link to profile
                content = new_page.search(".post__content").first.text # content
                unparsed_date = new_page.search(".user-info__meta").first.search("time")[0]["datetime"]
                title = new_page.search(".topic-header").search(".copy--h1").text
              
                # NO LOCATION...HAVE TO FIND ON PROFILE
                profile_page = agent.get(profile_url)
                location = profile_page.search(".current_location").last.text

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
  
  def self.parse_couch_surfing
    agent = Mechanize.new
    url = "https://www.couchsurfing.com/users/sign_in"
    agent.get(url)
    form = agent.page.forms.first
    form['user[login]'] = "jerrybarn10@gmail.com"
    form['user[password]'] = "3035jerry"
    form.submit

    # 20 per page
    100.times do |n|
      url_first = "https://www.couchsurfing.com/groups/14/page/"
      page_number = (n + 360).to_s
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
