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

  pros = client.get '/services/apexrest/DashboardPro', franchisee_id: ENV['FRANCHISEE_ID']

  loss = Hash.new
  loss2 = Hash.new

  group1 = pros.body.sort_by{|pro| pro.name}.each_slice(30).to_a[0]
  group2 = pros.body.sort_by{|pro| pro.name}.each_slice(30).to_a[1]

  group1.each do |pro|
    if pro.completed == 0
      loss_percentage = 0
    else
      loss_percentage = (pro.lost/pro.completed.round(2)*100).to_i
    end
    loss[pro] = { label: pro.name, value: "#{loss_percentage}%"}
  end

  group2.each do |pro|
    if pro.completed == 0
      loss_percentage = 0
    else
      loss_percentage = (pro.lost/pro.completed.round(2)*100).to_i
    end
    loss2[pro] = { label: pro.name, value: "#{loss_percentage}%"}
  end

  send_event('employee_loss', {items: loss.values})
  send_event('employee_loss_more', {items: loss2.values})

end
