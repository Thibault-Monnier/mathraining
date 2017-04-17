include ApplicationHelper

def sign_in(user)
  visit root_path
  fill_in "Email", with: user.email
  fill_in "Mot de passe", with: user.password
  click_button "Connexion"
end

def sign_out
	visit root_path
	click_link "Déconnexion"
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector('div.alert.alert-error', text: message)
  end
end
