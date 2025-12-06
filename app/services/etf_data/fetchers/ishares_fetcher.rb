require 'nokogiri'
require 'creek'
require 'csv'

module EtfData
  module Fetchers
    class IsharesFetcher < BaseFetcher
      JUSTETF_BASE_URL = "https://www.justetf.com/en/etf-profile.html"
      
      def initialize(provider)
        super
        @rate_limited = false
      end
      
      def rate_limited?
        @rate_limited
      end
      
      def fetch_etf_list(file_path = nil)
        unless file_path
          # If no file provided, download from iShares website (would need to be implemented)
          raise ArgumentError, "A file path must be provided for now"
        end
        
        process_etf_list_file(file_path)
      end
      
      def find_etf_url(etf)
        # Reset rate limited flag
        @rate_limited = false
        
        # Skip if URL already exists
        return etf.specific_url if etf.specific_url.present?
        
        isin = etf.formatted_metadata["isin"]
        unless isin.present?
          logger.error("Cannot find URL for ETF #{etf.ticker} (ID: #{etf.id}): No ISIN available in metadata")
          return nil
        end
        
        justetf_url = "#{JUSTETF_BASE_URL}?isin=#{isin}"
        logger.info("Attempting to find product URL for ETF #{etf.ticker} (ID: #{etf.id}) from JustETF: #{justetf_url}")
        
        # Use rate limiter for JustETF requests
        success, result = EtfData::RateLimiter.with_rate_limiting('justetf') do
          HTTParty.get(justetf_url)
        end
        
        unless success
          if result.is_a?(String)
            logger.error("JustETF request rate limited for ETF #{etf.ticker} (ISIN: #{isin}): #{result}")
            @rate_limited = true
          else
            logger.error("JustETF request failed for ETF #{etf.ticker} (ISIN: #{isin}): #{result.class.name} - #{result.message}")
            @rate_limited = result.respond_to?(:response) && result.response && result.response.code.to_i == 429
          end
          return nil
        end
        
        response = result
        
        if response.success?
          logger.debug("JustETF response for #{etf.ticker}: HTTP #{response.code}")
          page = Nokogiri::HTML(response.body)
          
          # Use the correct selector to find the provider button
          product_url_element = page.css('#provider-button').first
          
          if product_url_element
            product_url = product_url_element['href']
            etf.update(specific_url: product_url)
            logger.info("Found product URL for ETF #{etf.ticker}: #{product_url}")
            return product_url
          else
            logger.error("Could not find provider button element on JustETF page for ETF #{etf.ticker} (ISIN: #{isin}). CSS selector '#provider-button' returned no matches.")
            # Log a sample of the HTML for debugging
            html_sample = response.body.slice(0, 500) + "..."
            logger.debug("JustETF HTML sample: #{html_sample}")
          end
        else
          logger.error("JustETF request failed for ETF #{etf.ticker} (ISIN: #{isin}): HTTP #{response.code} - #{response.message}")
          
          # Check if rate limited
          if response.code.to_i == 429
            @rate_limited = true
          end
          
          # More detailed error info if available
          if response.body.present?
            error_sample = response.body.slice(0, 200) + "..."
            logger.error("JustETF error response: #{error_sample}")
          end
        end
        
        logger.error("Failed to find product URL for ETF #{etf.ticker} (ID: #{etf.id}) with ISIN #{isin}")
        nil
      end
      
      def fetch_etf_holdings(etf)
        # Reset rate limited flag
        @rate_limited = false
        
        unless etf.specific_url.present?
          logger.error("Cannot fetch holdings for ETF #{etf.ticker} (ID: #{etf.id}): No specific URL available")
          return nil
        end
        
        logger.info("Fetching holdings for ETF #{etf.ticker} from URL: #{etf.specific_url}")
        
        # Navigate to product page
        success, result = EtfData::RateLimiter.with_rate_limiting('ishares') do
          HTTParty.get(etf.specific_url)
        end
        
        unless success
          if result.is_a?(String)
            logger.error("Provider request rate limited for ETF #{etf.ticker}: #{result}")
            @rate_limited = true
          else
            logger.error("Provider request failed for ETF #{etf.ticker}: #{result.class.name} - #{result.message}")
            @rate_limited = result.respond_to?(:response) && result.response && result.response.code.to_i == 429
          end
          return nil
        end
        
        response = result
        
        unless response.success?
          logger.error("Failed to access product page for ETF #{etf.ticker} (ID: #{etf.id}): HTTP #{response.code} - #{response.message}")
          
          # Check if rate limited
          if response.code.to_i == 429
            @rate_limited = true
          end
          
          if response.body.present?
            error_sample = response.body.slice(0, 200) + "..."
            logger.error("Product page error: #{error_sample}")
          end
          return nil
        end
        
        page = Nokogiri::HTML(response.body)
        
        # Extract ETF price from header-nav-data span
        price_element = page.css('span.header-nav-data').first
        if price_element
          price_text = price_element.text.strip
          # Extract currency and price - expecting format like "USD 5,62"
          currency, price_str = price_text.split(' ', 2)
          
          if currency.present? && price_str.present?
            # Handle comma as decimal separator in European format
            price_str = price_str.gsub(',', '.')
            current_price = price_str.to_f
            
            logger.info("Extracted current price for ETF #{etf.ticker}: #{currency} #{current_price}")
            
            # Save the price information to the ETF record
            etf.update(
              current_price: current_price,
              currency: currency
            )
          else
            logger.warn("Could not parse price information from text: '#{price_text}' for ETF #{etf.ticker}")
          end
        else
          logger.warn("Could not find price element (span.header-nav-data) for ETF #{etf.ticker}")
        end
        
        # Use the correct selector to find the CSV download link
        csv_link_element = page.css('.holdings.fund-component-data-export a.icon-xls-export').first
        
        if csv_link_element
          csv_url = csv_link_element['href']
          logger.info("Found holdings CSV/XLS download link for ETF #{etf.ticker}: #{csv_url}")
          
          # Handle relative URLs by prepending the base URL if needed
          unless csv_url.start_with?('http')
            uri = URI.parse(etf.specific_url)
            base_url = "#{uri.scheme}://#{uri.host}"
            csv_url = "#{base_url}#{csv_url}"
            logger.debug("Expanded relative URL to absolute URL: #{csv_url}")
          end
          
          temp_dir = create_temp_directory
          csv_path = temp_dir.join("#{etf.ticker}_holdings.csv")
          
          # Use rate limiter for CSV download
          download_success, download_result = EtfData::RateLimiter.with_rate_limiting('ishares') do
            download_file(csv_url, csv_path)
          end
          
          unless download_success
            if download_result.is_a?(String)
              logger.error("CSV download rate limited for ETF #{etf.ticker}: #{download_result}")
              @rate_limited = true
            else
              logger.error("CSV download failed for ETF #{etf.ticker}: #{download_result.class.name} - #{download_result.message}")
              @rate_limited = download_result.respond_to?(:response) && download_result.response && download_result.response.code.to_i == 429
            end
            return nil
          end
          
          download_result = download_result # True or false from download_file
          
          if download_result
            logger.info("Successfully downloaded holdings file for ETF #{etf.ticker} to #{csv_path}")
            
            # Save a copy of the CSV file for header analysis
            save_csv_for_header_analysis(etf, csv_path)
            
            # Parse the CSV file using the appropriate parser
            parser = determine_parser_for_etf(etf)
            logger.debug("Using parser #{parser.class.name} for ETF #{etf.ticker}")
            
            begin
              holdings_data = parser.parse(csv_path.to_s)
              
              if holdings_data.empty?
                logger.error("Parser returned empty holdings data for ETF #{etf.ticker} (ID: #{etf.id})")
                return nil
              end
              
              logger.info("Successfully parsed #{holdings_data.size} holdings for ETF #{etf.ticker}")
              
              # Save to database
              as_of_date = parser.as_of_date || Date.today
              logger.info("Saving holdings for ETF #{etf.ticker} with as_of_date: #{as_of_date}")
              
              etf.update_holdings_from_data(holdings_data, as_of_date)
              
              # Return the data
              return holdings_data
            rescue => e
              logger.error("Error parsing holdings file for ETF #{etf.ticker} (ID: #{etf.id}): #{e.class.name} - #{e.message}")
              logger.error(e.backtrace.join("\n"))
              return nil
            end
          else
            logger.error("Failed to download holdings file for ETF #{etf.ticker} (ID: #{etf.id})")
            return nil
          end
        else
          logger.error("Could not find CSV/XLS download link for ETF #{etf.ticker} (ID: #{etf.id})")
          logger.debug("CSS selector '.holdings.fund-component-data-export a.icon-xls-export' returned no matches")
          return nil
        end
      end
      
      # Process a local ETF holdings file
      def process_holdings_file(ticker, file_path)
        # Find the ETF by ticker
        etf = Etf.find_by(ticker: ticker)
        
        unless etf
          logger.error("Cannot process holdings file: ETF #{ticker} not found")
          return nil
        end
        
        logger.info("Processing holdings file for ETF #{ticker} from local file: #{file_path}")
        
        # Save a copy of the CSV file for header analysis
        save_csv_for_header_analysis(etf, file_path) if etf
        
        begin
          # Choose appropriate parser
          parser = determine_parser_for_etf(etf)
          logger.debug("Using parser #{parser.class.name} for ETF #{ticker}")
          
          # Parse the file
          holdings_data = parser.parse(file_path)
          
          if holdings_data.empty?
            logger.error("Parser returned empty holdings data for ETF #{ticker}")
            return nil
          end
          
          logger.info("Successfully parsed #{holdings_data.size} holdings for ETF #{ticker}")
          
          # Save to database
          as_of_date = parser.as_of_date || Date.today
          logger.info("Saving holdings for ETF #{ticker} with as_of_date: #{as_of_date}")
          
          etf.update_holdings_from_data(holdings_data, as_of_date)
          
          # Return the data
          return holdings_data
        rescue => e
          logger.error("Error processing holdings file for ETF #{ticker}: #{e.class.name} - #{e.message}")
          logger.error(e.backtrace.join("\n"))
          return nil
        end
      end
      
      private
      
      def process_etf_list_file(file_path)
        logger.info("Processing ETF list file: #{file_path}")
        workbook = Creek::Book.new(file_path)
        sheet = workbook.sheets.first
        rows = sheet.simple_rows
        
        # Skip header row
        rows.shift
        
        etfs = []
        
        rows.each do |row|
          # Extract data from row (adjust indices as needed based on the file format)
          ticker = row["A"]
          name = row["B"]
          isin = row["C"]
          
          # Skip if required data is missing
          unless ticker.present? && name.present? && isin.present?
            logger.warn("Skipping row with missing data: #{row}")
            next
          end
          
          # Create or update ETF record
          etf = Etf.find_or_initialize_by(ticker: ticker)
          etf.name = name
          etf.provider = provider
          etf.metadata = {
            isin: isin,
            source_file: File.basename(file_path),
            imported_at: Time.current
          }
          
          if etf.save
            logger.info("#{etf.new_record? ? 'Created' : 'Updated'} ETF: #{ticker} (#{name})")
            etfs << etf
          else
            logger.error("Failed to save ETF #{ticker}: #{etf.errors.full_messages.join(', ')}")
          end
        end
        
        logger.info("Processed #{etfs.size} ETFs from file")
        etfs
      end
      
      def determine_parser_for_etf(etf)
        # Try to determine if this is a bond ETF based on name or ticker
        bond_keywords = ['bond', 'treasury', 'government', 'corporate', 'yield', 'duration', 'gilt', 'anleihe']
        
        is_bond = false
        
        # Check ETF name for bond keywords
        if etf.name.present?
          is_bond = bond_keywords.any? { |keyword| etf.name.downcase.include?(keyword) }
        end
        
        # Check asset class in metadata if available
        unless is_bond
          asset_class = etf.formatted_metadata["asset_class"]
          is_bond = asset_class == "Bond" || asset_class == "Anleihen" if asset_class.present?
        end
        
        # Use appropriate parser based on determination
        if is_bond
          logger.debug("Using bond parser for ETF #{etf.ticker} based on ETF characteristics")
          EtfData::Parsers::IsharesBondParser.new
        else
          logger.debug("Using equity parser for ETF #{etf.ticker} (default)")
          EtfData::Parsers::IsharesEquityParser.new
        end
      end
      
      def create_temp_directory
        temp_dir = Rails.root.join('tmp', 'etf_data')
        FileUtils.mkdir_p(temp_dir)
        temp_dir
      end
      
      # Save a copy of the CSV file for header analysis
      def save_csv_for_header_analysis(etf, source_path)
        # Create directory if it doesn't exist
        analysis_dir = Rails.root.join('tmp', 'csv_headers_analysis')
        FileUtils.mkdir_p(analysis_dir)
        
        # Create a filename with timestamp to avoid overwrites
        timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
        target_path = analysis_dir.join("#{etf.ticker}_#{timestamp}.csv")
        
        # Copy the file
        begin
          FileUtils.cp(source_path, target_path)
          logger.info("Saved copy of CSV file for header analysis: #{target_path}")
        rescue => e
          logger.error("Failed to save CSV copy for header analysis: #{e.message}")
        end
      end
    end
  end
end 