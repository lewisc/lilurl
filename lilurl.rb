require 'rubygems'
require 'sinatra'
require 'translate.rb'

$domain = 'localhost:4567'

get '/' do
  erb :index
end

get '/:hash' do
  if (params[:hash] != "favicon.ico")
    newurl=geturl(params[:hash])
    redirect to(newurl)
  end
end

post '/makeurl' do
  oldurl = params[:oldurl]
  newurl=makeurl(oldurl)
  erb :index, :locals => {:domain => $domain, :newurl => newurl}
end
