require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

# def clean_time_and_date(date)
#   Time.parse(date).to_s
# end


def clean_phone_number(phone_number)
  phone_number_copy = phone_number.gsub(/[^0-9]/, '').to_f.to_i.to_s
  if phone_number_copy.length < 10
    "0000000000"
  elsif phone_number_copy.length == 10
    phone_number_copy
  elsif phone_number_copy.length == 11
    if phone_number_copy[0] == "1"
      phone_number_copy[1..10]
    elsif phone_number_copy[0] != "1"
      "0000000000"
    end
  elsif phone_number_copy.length > 11
    "0000000000"
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hours = []
registration_days = []

contents.each do |row|
  id = row[:id]
  time = Time.strptime(row[:regdate], "%m/%d/%y %k:%M")
  date = Date.parse(time.to_s)
  hour = time.hour
  day = date.wday
  registration_hours.push(hour.to_s)
  registration_days.push(day.to_s)
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  puts "#{id}, #{hour}, #{day} #{name}, #{phone_number}, #{zipcode}"
end

h = registration_hours.tally.sort_by { |k, v| v }.reverse!.to_h
d = registration_days.tally.sort_by { |k, v| v }.reverse!.to_h

weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
most_frequent_hour = h.keys[0]
most_frequent_day = d.keys[0]

puts "Most busy hour for registration is #{most_frequent_hour}"
puts "Most busy day is #{weekdays[most_frequent_day.to_i]}"
