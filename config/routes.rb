ActionController::Routing::Routes.draw do |map|
  map.resources :mail, :path_prefix => "/pages/:page_id", :controller => "mail"
end
