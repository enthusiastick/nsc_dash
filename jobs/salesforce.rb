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
    closing_percentages[rep] = { label: rep, value: "#{(numbers[1]/numbers[0].round(2)*100).to_i}%" }
  end

  closing_percentages_recurring = Hash.new

  estimates_hash.each do |rep, numbers|
    closing_percentages_recurring[rep] = { label: rep, value: "#{(numbers[2]/numbers[0].round(2)*100).to_i}%" }
  end

  send_event('closing', { items: closing_percentages.values })
  send_event('closing_recurring', { items: closing_percentages_recurring.values })

end
