require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.gsub(/[^\d]/,"")
  phone_number[0] = '' if phone_number[0] == "1" && phone_number.length > 10
  phone_number = "0000000000" if phone_number.length != 10
end
def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
def get_peak_registration_hours(registration_hours)
  registration_hours.each_with_object(Hash.new(0)) do |hour, counts|
    counts[hour] += 1
  end.sort_by{ |k, v| v }.reverse.to_h
end
def get_peak_registration_days(registration_hours)
  p registration_hours
  days_of_week = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  registration_hours.each_with_object(Hash.new(0)) do |day, counts|
    day = days_of_week[day % 7]
    counts[day] += 1
  end.sort_by{ |k, v| v }.reverse.to_h
end
def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hours = Array.new()
registration_days = Array.new()
contents.each do |row|
  id = row[:id]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_days.push(Date.strptime("#{row[:regdate].split(" ")[0]}", "%D").wday)
  registration_hours.push(Time.parse(row[:regdate].split(" ")[1]).hour)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
p get_peak_registration_days(registration_days)
p get_peak_registration_hours(registration_hours)
