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

  send_event('employee_loss', {items: loss.values})

  dates1 = client.query("SELECT Name, (SELECT Name, Birthdate, Date_Of_Hire__c FROM Contacts WHERE Status__c != 'Inactive') FROM Account WHERE Id = '#{ENV['FRANCHISEE_1_ID']}'")
  dates2 = client.query("SELECT Name, (SELECT Name, Birthdate, Date_Of_Hire__c FROM Contacts WHERE Status__c != 'Inactive') FROM Account WHERE Id = '#{ENV['FRANCHISEE_2_ID']}'")

  # Change this back when QA is complete
  today = Date.today - 31

  special_days = Hash.new

  dates1.first.Contacts.each do |contact|
    unless contact.Birthdate.nil?
      birthday = Date.parse(contact.Birthdate)
      if birthday.month == today.month
        special_days[contact] = { label: "#{contact.Name} Birthday", value: birthday.strftime("%A, %B %-d"), order: birthday }
      end
    end
    unless contact.Date_Of_Hire__c.nil?
      hiredate = Date.parse(contact.Date_Of_Hire__c)
      if hiredate.month == today.month && hiredate.year != today.year
        special_days[contact] = { label: "#{contact.Name} #{today.year - hiredate.year}-Year Work Anniversary", value: hiredate.strftime("%A, %B %-d"), order: hiredate }
      end
    end
  end

  dates2.first.Contacts.each do |contact|
    unless contact.Birthdate.nil?
      birthday = Date.parse(contact.Birthdate)
      if birthday.month == today.month
        special_days[contact] = { label: "#{contact.Name} Birthday", value: birthday.strftime("%A, %B %-d"), order: birthday }
      end
    end
    unless contact.Date_Of_Hire__c.nil?
      hiredate = Date.parse(contact.Date_Of_Hire__c)
      if hiredate.month == today.month && hiredate.year != today.year
        special_days[contact] = { label: "#{contact.Name} #{(today.year - hiredate.year).to_s}-Year Work Anniversary", value: hiredate.strftime("%A, %B %-d"), order: hiredate }
      end
    end
  end

  send_event('special_days', {items: special_days.values.sort_by{ |entry| entry[:order] }})

  feedbacks_array = Array.new

  feedbacks1 = client.query("SELECT Name, (SELECT Is_there_anything_you_want_different__c, Date_of_Service__c, Feedback_Pro_Contacts__c, How_Likely_to_Recommend_Numeric__c, First_Name__c, Last_Name__c FROM Service_Feedback__r WHERE How_Likely_to_Recommend_Numeric__c >= 9 AND Date_of_Service__c = LAST_N_DAYS:60 ) FROM Account WHERE Id = '#{ENV['FRANCHISEE_1_ID']}'")

  feedbacks2 = client.query("SELECT Name, (SELECT Is_there_anything_you_want_different__c, Date_of_Service__c, Feedback_Pro_Contacts__c, How_Likely_to_Recommend_Numeric__c, First_Name__c, Last_Name__c FROM Service_Feedback__r WHERE How_Likely_to_Recommend_Numeric__c >= 9 AND Date_of_Service__c = LAST_N_DAYS:60 ) FROM Account WHERE Id = '#{ENV['FRANCHISEE_2_ID']}'")

  unless feedbacks1.first.Service_Feedback__r.nil?
    feedbacks1.first.Service_Feedback__r.each do |feedback|
      unless feedback.Is_there_anything_you_want_different__c.nil?
        feedbacks_array << { name: feedback.Feedback_Pro_Contacts__c, body: "[#{feedback.How_Likely_to_Recommend_Numeric__c.to_i}] #{feedback.Is_there_anything_you_want_different__c} - #{feedback.First_Name__c} #{feedback.Last_Name__c}", avatar: nil }
      end
    end
  end

  unless feedbacks2.first.Service_Feedback__r.nil?
    feedbacks2.first.Service_Feedback__r.each do |feedback|
      unless feedback.Is_there_anything_you_want_different__c.nil?
        feedbacks_array << { name: feedback.Feedback_Pro_Contacts__c, body: "[#{feedback.How_Likely_to_Recommend_Numeric__c.to_i}] #{feedback.Is_there_anything_you_want_different__c} - #{feedback.First_Name__c} #{feedback.Last_Name__c}", avatar: nil }
      end
    end
  end

  send_event('pro_feedback', comments: feedbacks_array)

  message = client.query("SELECT Franchisee_Dashboard_Message__c FROM Account WHERE Id = '#{ENV['FRANCHISEE_PARENT_ID']}'")

  send_event('message', text: message.first.Franchisee_Dashboard_Message__c)


end
