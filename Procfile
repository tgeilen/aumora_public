release: bundle exec rails db:migrate && npm install && npm run build
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 5 