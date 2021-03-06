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

  estimates = client.query("select Created_By_Name__c, Is_Closed_Won__c, Is_Closed_Won_Recurring__c from Estimate__c where Sales_Center_Billable__c = true and Managed_By__c = 'Sales Center' and CreatedDate = THIS_MONTH")

  closings_recurring = client.query("select Id from Estimate__c where Sales_Center_Billable__c = true and Managed_By__c = 'Sales Center' and Is_Closed_Won_Recurring__c = 1 and CreatedDate = THIS_MONTH")

  users_objects = client.query("select Name from User where Profile.name = 'Portal Sales Center User'")

  users = Array.new

  users_objects.each do |user_object|
    users << user_object.Name
  end

  estimates_hash = Hash.new

  estimates.each do |estimate|
    if estimates_hash[estimate.Created_By_Name__c].nil?
      estimates_hash[estimate.Created_By_Name__c] = [1,0,0]
      if estimate.Is_Closed_Won__c
        estimates_hash[estimate.Created_By_Name__c][1] += 1
      end
      if estimate.Is_Closed_Won_Recurring__c == 1
        estimates_hash[estimate.Created_By_Name__c][2] += 1
      end
    else
      estimates_hash[estimate.Created_By_Name__c][0] += 1
      if estimate.Is_Closed_Won__c
        estimates_hash[estimate.Created_By_Name__c][1] += 1
      end
      if estimate.Is_Closed_Won_Recurring__c == 1
        estimates_hash[estimate.Created_By_Name__c][2] += 1
      end
    end
  end

  closing_percentages = Hash.new

  estimates_hash.each do |rep, numbers|
    unless numbers[1] == 0
      percentage = (numbers[1]/numbers[0].round(2)*100).to_i
      unless percentage < 10
        unless percentage == 100
          if users.include?(rep)
            closing_percentages[rep] = { label: "#{rep} (#{numbers[1]}/#{numbers[0]})", value: "#{percentage}%" }
          end
        end
      end
    end
  end

  closing_percentages_recurring = Hash.new

  estimates_hash.each do |rep, numbers|
    unless numbers[2] == 0
      percentage_recurring = (numbers[2]/numbers[0].round(2)*100).to_i
      unless percentage_recurring < 10
        unless percentage_recurring == 100
          if users.include?(rep)
            closing_percentages_recurring[rep] = { label: "#{rep} (#{numbers[2]}/#{numbers[0]})", value: "#{percentage_recurring}%" }
          end
        end
      end
    end
  end

  send_event('closing', { items: closing_percentages.values })
  send_event('closing_recurring', { items: closing_percentages_recurring.values })
  send_event('closing_recurring_total', { current: closings_recurring.count })

end
