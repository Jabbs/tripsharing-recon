class ListingsController < ApplicationController
  
  def index
    @listings = Listing.where.not(latitude: nil)
    @hash = Gmaps4rails.build_markers(@listings) do |listing, marker|
      marker.lat listing.latitude
      marker.lng listing.longitude
      marker.infowindow listing.name
    end
  end
end
