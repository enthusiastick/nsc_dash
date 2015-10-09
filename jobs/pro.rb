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

end
