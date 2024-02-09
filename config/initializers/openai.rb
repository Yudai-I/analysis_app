OpenAI.configure do |config|
  config.access_token = ENV.fetch("gpt_key")
end
  