require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"
require "date"

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end

end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end 
end

def clean_phone(phonenumber)
  cleannumber = phonenumber.to_s.tr('^0-9', '')
  if cleannumber.length == 11 && cleannumber[0] == "1"
    cleannumber[1,10]
  elsif cleannumber.length == 10
    cleannumber
  else
    cleannumber = "NUMBER IS NO VALID"
  end
end


contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

puts "Iniciando evento"

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

registerarray = []
registerhash = {}

registerday = []
registerdayhash = {}

time = Time.new

time.strftime("%m,%d,%Y")

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
    
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)

  phonenumber = clean_phone(row[:homephone])

  register = row[:regdate]

  registerdate = register.split(" ")[1].split(":")[0].to_i

  registerarray.push(registerdate)

  dayoftheweek = register.split(" ")[0]

  registerday.push(Date.strptime(dayoftheweek, "%m/%d/%y"))

  save_thank_you_letter(id, form_letter)
  
end

registerarray.sort.each do |number|
  if !registerhash[number]
    registerhash[number] = 1
  else
    registerhash[number] += 1
  end
end

p registerhash ## 13hs and 16hs are with more activity

registerday.each do |date|
  exactday = date.wday
  if !registerdayhash[exactday]
    registerdayhash[exactday] = 1
  else
    registerdayhash[exactday] += 1
  end
end 

p registerdayhash ## Thursday is the day with more registers, five.
