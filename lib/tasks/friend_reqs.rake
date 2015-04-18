require 'csv'
namespace :friend_reqs do
  desc 'Do some friend reqs from couchsurfing analysis'
  task :analyze => :environment do
    
    old_names = []
    CSV.foreach('lib/assets/cs_friend_reqs.csv', headers: true, :encoding => 'windows-1251:utf-8') do |row|
      name = row[1]
      old_names << name 
    end
    
    
    new_names = []
    CSV.foreach('lib/assets/cs_friend_reqs.csv', headers: true, :encoding => 'windows-1251:utf-8') do |row|
      name = row[0]
      unless old_names.include?(name)
        new_names << name
      end
    end
    puts new_names.uniq.sort
  end
end