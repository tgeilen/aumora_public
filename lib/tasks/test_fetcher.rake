namespace :test do
  desc "Test fetcher class loading"
  task fetcher: :environment do
    begin
      puts "Loading EtfData::Fetchers::BaseFetcher..."
      base_class = EtfData::Fetchers::BaseFetcher
      puts "Successfully loaded BaseFetcher: #{base_class}"
      
      puts "Loading EtfData::Fetchers::IsharesFetcher..."
      ishares_class = EtfData::Fetchers::IsharesFetcher
      puts "Successfully loaded IsharesFetcher: #{ishares_class}"
      
      # Test creating an instance
      puts "Creating an instance of IsharesFetcher..."
      provider = EtfProvider.find_by(name: 'iShares')
      
      if provider
        fetcher = ishares_class.new(provider)
        puts "Successfully created IsharesFetcher instance: #{fetcher}"
      else
        puts "Cannot create IsharesFetcher instance - no iShares provider found in database"
      end
      
      puts "Test completed successfully!"
    rescue => e
      puts "Error during test: #{e.class.name} - #{e.message}"
      puts e.backtrace
    end
  end
end 