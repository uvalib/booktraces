namespace :users do

   desc "Seed some staff members"
   task :seed  => :environment do
      User.create([
         {computing_id: "lf6f", last_name: "Foster", first_name: "Lou", is_active: true},
         {computing_id: "khj5c", last_name: "Jensen", first_name: "Kristin", is_active: true}
      ])
   end

   desc "Add staff members"
   task :add  => :environment do
      id = ENV['id']
      lname = ENV['lname']
      fname = ENV['fname']
      abort("id, lname and fname are required") if id.nil? || lname.nil? || fname.nil?
      User.create(computing_id: if, last_name: lname, first_name: fname, is_active: true)
   end
end
