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
    50.times do |n|
      url_first = "https://www.lonelyplanet.com/thorntree/forums/travel-companions?page="
      page_number = (n + 1).to_s
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
                  sleep 5
                end
              end
              
            end
          end
        end
      end
      
    end
  end
  
  def self.parse_travel_buddies
    agent = Mechanize.new
    url = 'http://www.travel-buddies.com/LoginOrRegister.aspx'
    agent.get(url)
    form = agent.page.forms_with(id: "form1").first
    form['txtLogin_Email'] = "petejabbour1@gmail.com"
    form['txtLogin_Password'] = "H96+dyKf}2zZ"
    form.click_button(form.buttons.first)
        
    10.times do |n|
      url_first = "http://www.travel-buddies.com/Public-Wall.aspx?Page="
      page_number = (n + 1).to_s
      url = url_first + page_number
      page = agent.get(url)
      
      profile_boxes = page.search(".ProfileBox")
      profile_boxes.each do |pb|
        profile_id = pb.search("a")[0]["href"].split("=").last
        first_half_of_profile_url = "http://www.travel-buddies.com/View-Profile.aspx?ID="
        url = first_half_of_profile_url + profile_id
        page = agent.get(url)
        gender = page.search("#ProfileData").search("#lblSex").text
        location = page.search("#PersonalDetails").search(".PersonalDetails").search("a").text

        unparsed_location_nationality_relationship_and_age = page.search("#PersonalDetails").search(".PersonalDetails").text
        unparsed_location_nationality_relationship_and_age.slice!(location) # removes location
        unparsed_nationality_relationship_and_age = unparsed_location_nationality_relationship_and_age.split(",")

        nationality = unparsed_nationality_relationship_and_age[0]
        relationship_status = unparsed_nationality_relationship_and_age[1]
        age = unparsed_nationality_relationship_and_age[2]
        name = page.search(".ProfileHomeName").text

        if page.search(".dlTravelPlans").any?
          trip_destination = page.search(".dlTravelPlans").search(".CountryLabel").text.split(",").first
          trip_status = page.search(".dlTravelPlans").search(".RegionLabel").text.split("-").first.strip
          trip_departs_at = page.search(".dlTravelPlans").search(".RegionLabel").text.split("-").last.split("to").first.strip
          trip_returns_at = page.search(".dlTravelPlans").search(".RegionLabel").text.split("-").last.split("to").last.split("(").first.strip
          begin
            trip_departs_at = trip_departs_at.try(:to_datetime)
            trip_returns_at = trip_returns_at.try(:to_datetime)
            skip_create = false
          rescue ArgumentError
            puts "date error"
            skip_create = true
          end
          trip_duration = page.search(".dlTravelPlans").search(".RegionLabel").text.split("-").last.split("to").last.split("(").last.strip.delete(")")
          trip_type = page.search("#dlRoutes_ctl00_TripTypeLabel").text
          trip_traveling_by = page.search("#dlRoutes_ctl00_TravellingByLabel").text
          trip_staying_in = page.search("#dlRoutes_ctl00_StayingInLabel").text
        else
          trip_destination = ""; trip_status = ""; trip_departs_at = nil; trip_returns_at = nil; trip_duration = ""
          trip_type = ""; trip_traveling_by = ""; trip_staying_in = ""
        end

        # puts "Dest: #{trip_destination}, Status: #{trip_status}, Departs at: #{trip_departs_at}, Returns: #{trip_returns_at}, Duration: #{trip_duration}, Type: #{trip_type}, Mode of transit: #{trip_traveling_by}, Staying in: #{trip_staying_in}"

        source = "tb"
        unless skip_create == true
          listing = Listing.create(source: source, url: url, name: name, profile_url: url, location: location,
                    content: "", unparsed_date: nil, title: "", trip_destination: trip_destination,
                    trip_status: trip_status, trip_departs_at: trip_departs_at, trip_returns_at: trip_returns_at,
                    trip_duration: trip_duration, trip_type: trip_type, trip_traveling_by: trip_traveling_by,
                    trip_staying_in: trip_staying_in, gender: gender, age: age, relationship_status: relationship_status,
                    nationality: nationality)
          if listing.present?
            Rails.logger.info "Listing created: id: #{listing.id}, Location: #{listing.location}, lat: #{listing.latitude} long: #{listing.longitude}"
            sleep 5
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
    50.times do |n|
      url_first = "https://www.couchsurfing.com/groups/14/page/"
      page_number = (n + 1).to_s
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
                sleep 5
              end
            end
          end
        end
      end
    end
  end
  
  def self.friend_couch_surfers
    agent = Mechanize.new
    url = "https://www.couchsurfing.com/users/sign_in"
    agent.get(url)
    form = agent.page.forms.first
    form['user[login]'] = "petejabbour1@gmail.com"
    form['user[password]'] = "M#94uGR/b8DA"
    form.submit
    
    10.times do |n|
      url_first = "https://www.couchsurfing.com/groups/14/page/"
      page_number = (n + 1).to_s
      url = url_first + page_number
      page = agent.get(url)
      
      page.search(".comment__image").each do |image|
        href = image.search("a")[0]["href"]
        if href.present?
          url = "https://www.couchsurfing.com" + href
          page = agent.get(url)
          if page.search(".cs-dropdown-menu").search("li").any?
            friending = page.search(".cs-dropdown-menu").search("li").first.text.strip
            if friending == "Friend Request Sent" || friending == "Remove Friend"
              name = page.search(".cs-profile-title").text.strip
              puts name + " | #{page_number}"
            end
          end
            
          # page.links.each do |link|
          #   if link.text == "Add Friend"
          #     begin
          #       link.click
          #     rescue Mechanize::ResponseCodeError
          #     end
          #     name = page.search(".cs-profile-title").text.strip
          #     location = page.search(".cs-profile-subtitle").text.strip
          #     Rails.logger.info "#{name}. #{location}"
          #     sleep rand(200..600)
          #   end
          # end
          
        end
      end
    end
    
  end
  
end
