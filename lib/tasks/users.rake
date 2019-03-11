namespace :users do

   desc "Seed some staff members"
   task :seed  => :environment do
      User.create([
         {computing_id: "lf6f", last_name: "Foster", first_name: "Lou", is_active: true},
         {computing_id: "khj5c", last_name: "Jensen", first_name: "Kristin", is_active: true}
      ])
   end

   desc "Add BT API Key"
   task :api  => :environment do
      ApiKey.create(email:"booktraces",first_name:"book", last_name: "traces")
   end

   desc "Add staff members"
   task :add  => :environment do
      id = ENV['id']
      lname = ENV['lname']
      fname = ENV['fname']
      abort("id, lname and fname are required") if id.nil? || lname.nil? || fname.nil?
      User.create(computing_id: id, last_name: lname, first_name: fname, is_active: true)
   end

   desc "Export staff"
   task :export => :environment do
      out = []
      User.where(is_active: 1).each do |u|
         out << { computing_id: u.computing_id, last_name: u.last_name, first_name: u.first_name}
      end
      puts out.to_json
   end

   desc "Import staff"
   task :import => :environment do
      file = ENV['file']
      abort("File is required") if file.nil?
      dat = File.read(file)
      JSON.parse(dat).each do |u|
         puts "USER: #{u['computing_id']}..."
         if User.find_by(computing_id: u['computing_id']).nil?
            puts "  creating"
            User.create(is_active: 1, computing_id: u['computing_id'],
               first_name: u['first_name'], last_name: u['last_name'])
         else
            puts "  #{u['computing_id']} exists; skipping"
         end
      end
   end
end
