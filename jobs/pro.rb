require 'faye'
require 'pry'
require 'restforce'

SCHEDULER.every '1m', :first_in => 0 do

  client = Restforce.new :username => ENV['SALESFORCE_USERNAME'],
  :password       => ENV['SALESFORCE_PASSWORD'],
  :security_token => ENV['SALESFORCE_SECURITY_TOKEN'],
  :host           => ENV['SALESFORCE_HOST'],
  :client_id      => ENV['SALESFORCE_CLIENT_ID'],
  :client_secret  => ENV['SALESFORCE_CLIENT_SECRET']

  pros1 = client.get '/services/apexrest/DashboardPro', franchisee_id: ENV['FRANCHISEE_1_ID']
  pros2 = client.get '/services/apexrest/DashboardPro', franchisee_id: ENV['FRANCHISEE_2_ID']

  sorted_pros1 = pros1.body.sort_by{|pro| pro.name}
  sorted_pros2 = pros2.body.sort_by{|pro| pro.name}

  combined_pros = (sorted_pros1 << sorted_pros2).flatten

  combined_sorted_pros = combined_pros.sort_by{|pro| pro.name}

  loss = Hash.new

  combined_sorted_pros.each do |pro|
    if pro.completed == 0
      loss_percentage = 0
    else
      loss_percentage = (pro.lost/pro.completed.round(2)*100).to_i
    end
    loss[pro] = { label: pro.name, value: "#{loss_percentage}%"}
  end

  # puts loss.values
  send_event('employee_loss', {items: loss.values})

  dates1 = client.query("SELECT Name, (SELECT Name, Birthdate, Date_Of_Hire__c FROM Contacts WHERE Status__c != 'Inactive') FROM Account WHERE Id = '#{ENV['FRANCHISEE_1_ID']}'")
  dates2 = client.query("SELECT Name, (SELECT Name, Birthdate, Date_Of_Hire__c FROM Contacts WHERE Status__c != 'Inactive') FROM Account WHERE Id = '#{ENV['FRANCHISEE_2_ID']}'")

  today = Date.today

  special_days = Hash.new

  dates1.first.Contacts.each do |contact|
    unless contact.Birthdate.nil?
      if Date.parse(contact.Birthdate).month == today.month
        special_days[contact] = { label: "#{contact.Name} Birthday", value: Date.parse(contact.Birthdate).strftime("%A, %B %-d"), order: Date.parse(contact.Birthdate) }
      end
    end
    unless contact.Date_Of_Hire__c.nil?
      if Date.parse(contact.Date_Of_Hire__c).month == today.month
        special_days[contact] = { label: "#{contact.Name} Work Anniversary", value: Date.parse(contact.Date_Of_Hire__c).strftime("%A, %B %-d"), order: Date.parse(contact.Date_Of_Hire__c) }
      end
    end
  end

  dates2.first.Contacts.each do |contact|
    unless contact.Birthdate.nil?
      if Date.parse(contact.Birthdate).month == today.month
        special_days[contact] = { label: "#{contact.Name} Birthday", value: Date.parse(contact.Birthdate).strftime("%A, %B %-d"), order: Date.parse(contact.Birthdate) }
      end
    end
    unless contact.Date_Of_Hire__c.nil?
      if Date.parse(contact.Date_Of_Hire__c).month == today.month
        special_days[contact] = { label: "#{contact.Name} Work Anniversary", value: Date.parse(contact.Date_Of_Hire__c).strftime("%A, %B %-d"), order: Date.parse(contact.Date_Of_Hire__c) }
      end
    end
  end

  send_event('special_days', {items: special_days.values.sort_by{ |entry| entry[:order] }})

end
