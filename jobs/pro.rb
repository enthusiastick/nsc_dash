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

  feedback = Array.new
  feedback << { name: "Abbaz Ca, Ch, So, Bouchrda", body: "[10] Thanks Bouchra! - Steven Bennett", avatar: nil }
  feedback << { name: "Barrios CA SO, Diana", body: "[9] Diana does a wonderful job and is extremely pleasant. - suzanne hill", avatar: nil }
  feedback << { name: "Bernardo BB SE, Marcia", body: "[10] Marcia was great as always! Thank you - Yana Harris", avatar: nil }
  feedback << { name: "Cordero BB SE, Dana", body: "[9] Everything was cleaned to perfection, and it was extremely easy to arrange! - Tory Starr", avatar: nil }
  feedback << { name: "Fuentes Cha, Ca, So, Gladys", body: "[9] Wonderful job overall. - Shannon Brady", avatar: nil }
  feedback << { name: "Maldonado BB SE, Grechie", body: "[10] Great job - everything looked perfectly clean, sheets were changed, bathroom was tidy and trash was removed. Very happy. - Danielle Schley", avatar: nil }
  feedback << { name: "McGourthy NE BH CRP, Lisa", body: "[10] I really appreciated that Lisa helped me do a couple of things that I couldn't do because I can no longer reach them. - Virginia Costello", avatar: nil }
  feedback << { name: "Montes CA SO, Alba", body: "[10] she did a great job & i hope to see her next month!!! - Margaret Hazelwood", avatar: nil }
  feedback << { name: "Montes CA SO, Alba", body: "[10] The women that came out and cleaned my home was phenomenal !! I would recommend her to anybody ! She was so sweet and friendly has made my home look like the first day I moved in ! It was spotless :) - Jillian Gaeta", avatar: nil }
  feedback << { name: "Rosario CA SO, Alexandra", body: "[10] I hired a flat for 1.5 months on Airbnb and the place was filthy. Maid Pro cleared all of the grime in just four hours and made the place livable. THANK YOU!", avatar: nil }
  feedback << { name: "Silva BB, SE, Deolinda", body: "[10] Linda as always was great and did a fantastic job! Happy Thanksgiving everyone!", avatar: nil }
  feedback << { name: "Xiao Shun BB SE, Huo Susan", body: "[9] Complete turn around. Susan was fantastic, so much so that we only want her.", avatar: nil }

  send_event('pro_feedback', comments: feedback)

end
