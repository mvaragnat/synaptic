Rails.application.routes.draw do

  resources :elements
  match 'create_from_address', to: 'elements#create_from_address', via: 'post'

  root 'watson#home'

  #watson
  match 'send_element_from_address', to: 'watson#send_element_from_address', via: 'post'
  match 'conceptual_search', to: 'watson#conceptual_search', via: 'post'

end
