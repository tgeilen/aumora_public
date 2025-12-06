module EtfData
  module Parsers
    class IsharesEquityParser < BaseParser
      def parse(file_path)
        content = File.read(file_path, encoding: 'bom|utf-8')
        
        # Log the file we're processing
        Rails.logger.info("Parsing equity CSV file: #{file_path}")
        
        # Extract as_of_date from the file
        match = content.match(/(?:Fund Holdings as of|Fondsposition per)[\s,]*"([^"]+)"/)
        if match && match[1]
          @as_of_date = parse_date(match[1])
          Rails.logger.info("Extracted as_of_date: #{@as_of_date}")
        end
        
        # Default to today if we couldn't extract a date
        @as_of_date ||= Date.today
        
        # First try the standard approach
        begin
          # Initial parsing to determine the format
          csv_options = determine_csv_options(content)
          csv = parse_csv(file_path, csv_options)
          
          # Find the row with column headers
          header_row_index = find_header_row_index(csv)
          Rails.logger.info("Header row index determined to be: #{header_row_index}")
          
          # If the headers aren't on the first row, we need to re-parse with the correct header row
          if header_row_index > 0
            # Reset the CSV parser with the correct header row
            csv_options[:headers] = header_row_index
            csv = parse_csv(file_path, csv_options)
            
            # Verify that we have proper headers now
            Rails.logger.info("Re-parsed CSV with headers at row #{header_row_index}, headers: #{csv.headers.inspect}")
          else
            Rails.logger.info("Using original CSV parse with headers: #{csv.headers.inspect}")
          end
          
          # Handle the case where we have headers but they're not in the expected format
          if csv.headers && csv.headers.size < 3
            raise "CSV headers seem incomplete, trying manual parsing"
          end
          
          # Map columns based on language
          column_mapping = determine_column_mapping(csv.headers)
          
          # Check if we have the essential columns
          if column_mapping[:ticker].nil? || column_mapping[:name].nil? || column_mapping[:weight].nil?
            raise "Missing essential columns in column mapping, trying manual parsing"
          end
          
          # Process holdings
          process_holdings(csv, column_mapping)
        rescue => e
          # If standard parsing fails, try manual parsing
          Rails.logger.warn("Standard parsing failed: #{e.message}. Trying manual parsing approach.")
          
          # Parse the CSV manually
          manual_parse_result = manual_parse(content)
          
          if manual_parse_result && manual_parse_result.any?
            Rails.logger.info("Manual parsing succeeded with #{manual_parse_result.size} holdings")
            manual_parse_result
          else
            Rails.logger.error("Manual parsing also failed")
            []
          end
        end
      end
      
      protected
      
      def process_holdings(csv, column_mapping)
        holdings = []
        seen_tickers = {}
        seen_names = {}
        
        Rails.logger.info("Processing holdings with column mapping: #{column_mapping.inspect}")
        Rails.logger.info("CSV headers: #{csv.headers.inspect}")
        
        # Debug: Log first few rows to examine price data
        Rails.logger.info("Examining first 3 rows of CSV for price data:")
        csv.first(3).each_with_index do |row, index|
          price_column = column_mapping[:price]
          currency_column = column_mapping[:currency]
          if price_column
            Rails.logger.info("Row #{index} - Price column '#{price_column}' value: #{row[price_column].inspect}")
          else
            Rails.logger.info("Row #{index} - No price column mapped!")
          end
          if currency_column
            Rails.logger.info("Row #{index} - Currency column '#{currency_column}' value: #{row[currency_column].inspect}")
          else
            Rails.logger.info("Row #{index} - No currency column mapped!")
          end
        end
        
        begin
          csv.each do |row|
            ticker = row[column_mapping[:ticker]]&.strip
            name = row[column_mapping[:name]]&.strip
            
            Rails.logger.debug("Processing row with ticker: #{ticker}, name: #{name}")
            
            # Skip sector summary rows
            next if is_sector_summary(ticker, name)
            
            # Skip rows with missing essential data
            next if name.blank?
            
            # Get weight, if provided
            weight = 0
            if column_mapping[:weight]
              raw_weight = row[column_mapping[:weight]]&.strip
              Rails.logger.debug("Raw weight value: #{raw_weight.inspect}")
              weight = extract_percentage(raw_weight)
              Rails.logger.debug("Extracted weight: #{weight} from #{raw_weight}")
              
              # Handle negative weights
              is_short = weight < 0
              if is_short
                if name.to_s.downcase.include?('cash') || name.to_s.downcase.include?('cash')
                  # For cash positions, mark as short in the name
                  name = "#{name} (Short)" unless name.include?('(Short)')
                end
                # Always use absolute value for weight to satisfy model validation
                weight = weight.abs
                Rails.logger.info("Converting negative weight to positive for #{name}: #{-weight} -> #{weight}")
              end
            end
            
            # Skip entries with zero weight unless they are cash/derivative positions
            if weight == 0 && !name.to_s.downcase.include?('cash') && !name.to_s.downcase.include?('derivate')
              Rails.logger.debug("Skipping entry with zero weight: #{name}")
              next
            end
            
            # Generate identifier based on ticker or name
            identifier = if ticker.present?
              ticker
            else
              # Use a hash of the name if no ticker is available
              name.parameterize
            end
            
            # Get sector, if provided
            sector = nil
            if column_mapping[:sector]
              sector = normalize_sector(row[column_mapping[:sector]]&.strip)
            end
            
            # Get asset class, if provided
            asset_class = 'equity'
            if column_mapping[:asset_class]
              asset_class = determine_asset_type(row[column_mapping[:asset_class]]&.strip)
            end
            
            # Get country, if provided
            country = nil
            if column_mapping[:country]
              country = normalize_country(row[column_mapping[:country]]&.strip)
            end
            
            # Extract price information - NEW
            price = nil
            currency = nil
            
            if column_mapping[:price]
              price_str = row[column_mapping[:price]]&.strip
              Rails.logger.info("For asset #{ticker || name} - Raw price data: #{price_str.inspect}")
              if price_str.present?
                # Handle different number formats (comma/period as decimal separator)
                price_str = price_str.gsub(',', '.') if price_str.include?(',')
                price = price_str.to_f
                Rails.logger.info("Extracted price: #{price} from #{price_str}")
              else
                Rails.logger.info("Price data was empty or nil for asset #{ticker || name}")
              end
            else
              Rails.logger.info("No price column mapped for asset #{ticker || name}")
            end
            
            if column_mapping[:currency]
              currency = row[column_mapping[:currency]]&.strip
              Rails.logger.info("For asset #{ticker || name} - Currency: #{currency.inspect}")
            else
              Rails.logger.info("No currency column mapped for asset #{ticker || name}")
            end
            
            # Create the holding object
            holding = {
              ticker: ticker,
              name: name,
              weight: weight,
              identifier: identifier,
              as_of_date: @as_of_date
            }
            
            # Add additional fields if they exist
            holding[:sector] = sector if sector.present?
            holding[:asset_class] = asset_class if asset_class.present?
            holding[:country] = country if country.present?
            holding[:price] = price if price.present?
            holding[:currency] = currency if currency.present?
            
            Rails.logger.debug("Adding holding: #{holding.inspect}")
            
            # Only add if we haven't seen this exact holding before
            holdings << holding unless holdings.any? { |h| h[:identifier] == identifier && h[:as_of_date] == @as_of_date }
          end
        rescue => e
          Rails.logger.error("Error processing row in IsharesEquityParser: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
        
        Rails.logger.info("Processed #{holdings.size} holdings")
        
        # Log sample of holdings with price data
        with_price = holdings.select { |h| h[:price].present? }
        Rails.logger.info("Holdings with price data: #{with_price.size}/#{holdings.size}")
        if with_price.any?
          sample = with_price.first(3)
          Rails.logger.info("Sample holdings with price data:")
          sample.each do |h|
            Rails.logger.info("  #{h[:ticker] || h[:name]}: Price #{h[:price]} #{h[:currency]}")
          end
        else
          Rails.logger.warn("NO HOLDINGS HAVE PRICE DATA!")
        end
        
        holdings
      end
      
      private
      
      def determine_csv_options(content)
        # Determine delimiter based on file content
        if content.include?(';')
          { col_sep: ';' }
        else
          { col_sep: ',' }
        end
      end
      
      def find_header_row_index(csv)
        # Look for a row that contains typical column headers
        csv.each_with_index do |row, index|
          row_values = row.to_h.values.join(' ').downcase
          
          if (row_values.include?('ticker') && row_values.include?('weight')) ||
             (row_values.include?('emittententicker') && row_values.include?('gewichtung'))
            Rails.logger.info("Found header row at index #{index}")
            Rails.logger.info("Header row values: #{row_values}")
            return index
          end
        end
        
        0 # Default to first row if no header row found
      end
      
      def determine_column_mapping(headers)
        # Convert headers to strings and downcase for comparison
        headers = headers.map { |h| h.to_s.downcase }
        
        Rails.logger.info("Determining equity column mapping for headers: #{headers}")
        
        # Log all headers to verify what's available
        headers.each_with_index do |header, idx|
          Rails.logger.info("  Header #{idx}: '#{header}'")
        end
        
        # Look for price-related headers with more flexible matching
        price_header = headers.find { |h| h == 'price' || h == 'preis' || h == 'kurs' || h == 'market price' || h.include?('price') || h.include?('preis') }
        if price_header
          Rails.logger.info("Found price header: '#{price_header}'")
        else
          Rails.logger.warn("No price header found among available headers!")
        end
        
        # Look for currency-related headers with more flexible matching
        currency_header = headers.find { |h| h == 'currency' || h == 'währung' || h == 'marktwährung' || h.include?('currency') || h.include?('währung') }
        if currency_header
          Rails.logger.info("Found currency header: '#{currency_header}'")
        else
          Rails.logger.warn("No currency header found among available headers!")
        end
        
        # Default mapping for English format
        if headers.any? { |h| h.include?('ticker') }
          {
            ticker: headers.find { |h| h == 'ticker' },
            name: headers.find { |h| h == 'name' },
            sector: headers.find { |h| h == 'sector' },
            asset_class: headers.find { |h| h == 'asset class' },
            weight: headers.find { |h| h.include?('weight') },
            country: headers.find { |h| h == 'location' },
            price: price_header,
            currency: currency_header
          }
        # Mapping for German format
        else
          {
            ticker: headers.find { |h| h.include?('emittententicker') },
            name: headers.find { |h| h == 'name' }, # 'Name' is the same in German and English
            sector: headers.find { |h| h == 'sektor' },
            asset_class: headers.find { |h| h == 'anlageklasse' },
            weight: headers.find { |h| h.include?('gewichtung') || h.include?('(%)') },
            country: headers.find { |h| h == 'standort' },
            price: price_header,
            currency: currency_header
          }
        end.tap do |mapping|
          # Log the mapping for debugging
          Rails.logger.info("Equity column mapping: #{mapping.inspect}")
        end.transform_values { |header| header.to_s if header }
      end
      
      def manual_parse(content)
        lines = content.lines
        
        # Look for the header line
        header_line_index = -1
        header_line = nil
        
        lines.each_with_index do |line, idx|
          if line.downcase.include?('emittententicker') || 
             (line.downcase.include?('ticker') && line.downcase.include?('name'))
            header_line_index = idx
            header_line = line
            Rails.logger.info("Found header line at index #{idx}: #{line.strip}")
            break
          end
        end
        
        return [] if header_line_index < 0
        
        # Parse the header line to get column indices
        delimiter = content.include?(';') ? ';' : ','
        headers = CSV.parse_line(header_line, col_sep: delimiter)
        
        Rails.logger.info("Parsed headers: #{headers.inspect}")
        
        # Log all headers to verify what's available
        headers.each_with_index do |header, idx|
          Rails.logger.info("  Manual parse header #{idx}: '#{header}'")
        end
        
        # Determine column indices
        ticker_idx = headers.find_index { |h| h&.downcase&.include?('emittententicker') || h&.downcase == 'ticker' }
        name_idx = headers.find_index { |h| h&.downcase == 'name' }
        sector_idx = headers.find_index { |h| h&.downcase == 'sektor' || h&.downcase == 'sector' }
        asset_class_idx = headers.find_index { |h| h&.downcase == 'anlageklasse' || h&.downcase == 'asset class' }
        weight_idx = headers.find_index { |h| h&.downcase&.include?('gewichtung') || h&.downcase&.include?('weight') }
        country_idx = headers.find_index { |h| h&.downcase == 'standort' || h&.downcase == 'location' }
        
        # More flexible price/currency column detection
        price_idx = headers.find_index { |h| h&.downcase == 'preis' || h&.downcase == 'price' || h&.downcase == 'kurs' || h&.downcase == 'market price' || 
                                         h&.downcase&.include?('price') || h&.downcase&.include?('preis') }
        currency_idx = headers.find_index { |h| h&.downcase == 'währung' || h&.downcase == 'currency' || 
                                            h&.downcase == 'marktwährung' || h&.downcase&.include?('currency') || 
                                            h&.downcase&.include?('währung') }
        
        if price_idx
          Rails.logger.info("Found manual price column at index #{price_idx}: '#{headers[price_idx]}'")
        else
          Rails.logger.warn("No price column found in manual parsing!")
        end
        
        if currency_idx
          Rails.logger.info("Found manual currency column at index #{currency_idx}: '#{headers[currency_idx]}'")
        else
          Rails.logger.warn("No currency column found in manual parsing!")
        end
        
        Rails.logger.info("Column indices - ticker: #{ticker_idx}, name: #{name_idx}, weight: #{weight_idx}, price: #{price_idx}, currency: #{currency_idx}")
        
        # Check if we have the essential columns
        if ticker_idx.nil? || name_idx.nil? || weight_idx.nil?
          Rails.logger.error("Missing essential columns in headers")
          return []
        end
        
        # Process data rows
        holdings = []
        
        lines[(header_line_index + 1)..].each do |line|
          begin
            # Skip empty lines
            next if line.strip.empty?
            
            # Parse the line
            row = CSV.parse_line(line, col_sep: delimiter)
            next unless row && row.size >= [ticker_idx, name_idx, weight_idx].compact.max
            
            ticker = row[ticker_idx]&.strip
            name = row[name_idx]&.strip
            
            Rails.logger.debug("Processing row with ticker: #{ticker}, name: #{name}")
            
            # Skip rows with missing essential data
            next if name.blank?
            
            # Skip sector summary rows
            next if is_sector_summary(ticker, name)
            
            # Get weight
            weight = 0
            if weight_idx && row[weight_idx]
              raw_weight = row[weight_idx]&.strip
              Rails.logger.debug("Raw weight value: #{raw_weight.inspect}")
              weight = extract_percentage(raw_weight)
              Rails.logger.debug("Extracted weight: #{weight} from #{raw_weight}")
              
              # Handle negative weights
              is_short = weight < 0
              if is_short
                if name.to_s.downcase.include?('cash') || name.to_s.downcase.include?('bargeld')
                  # For cash positions, mark as short in the name
                  name = "#{name} (Short)" unless name.include?('(Short)')
                end
                # Always use absolute value for weight to satisfy model validation
                weight = weight.abs
                Rails.logger.info("Converting negative weight to positive for #{name}: #{-weight} -> #{weight}")
              end
            end
            
            # Skip entries with zero weight unless they are cash/derivative positions
            if weight == 0 && !name.to_s.downcase.include?('cash') && !name.to_s.downcase.include?('derivate')
              Rails.logger.debug("Skipping entry with zero weight: #{name}")
              next
            end
            
            # Get sector
            sector = nil
            if sector_idx && row[sector_idx]
              sector = normalize_sector(row[sector_idx]&.strip)
            end
            
            # Get asset class
            asset_class = 'equity'
            if asset_class_idx && row[asset_class_idx]
              asset_class = determine_asset_type(row[asset_class_idx]&.strip)
            end
            
            # Get country
            country = nil
            if country_idx && row[country_idx]
              country = normalize_country(row[country_idx]&.strip)
            end
            
            # Extract price information
            price = nil
            currency = nil
            
            if price_idx && row[price_idx]
              price_str = row[price_idx]&.strip
              Rails.logger.info("Manual parse: for asset #{ticker || name} - Raw price data: #{price_str.inspect}")
              if price_str.present?
                # Handle different number formats (comma/period as decimal separator)
                price_str = price_str.gsub(',', '.') if price_str.include?(',')
                price = price_str.to_f
                Rails.logger.info("Manual parse: extracted price: #{price} from #{price_str}")
              else
                Rails.logger.info("Manual parse: price data was empty or nil for asset #{ticker || name}")
              end
            else
              Rails.logger.info("Manual parse: no price column available for asset #{ticker || name}")
            end
            
            if currency_idx && row[currency_idx]
              currency = row[currency_idx]&.strip
              Rails.logger.info("Manual parse: for asset #{ticker || name} - Currency: #{currency.inspect}")
            else
              Rails.logger.info("Manual parse: no currency column available for asset #{ticker || name}")
            end
            
            # Create the holding object
            holding = {
              ticker: ticker,
              name: name,
              weight: weight,
              identifier: ticker || name.parameterize,
              as_of_date: @as_of_date
            }
            
            # Add additional fields if they exist
            holding[:sector] = sector if sector.present?
            holding[:asset_class] = asset_class if asset_class.present?
            holding[:country] = country if country.present?
            holding[:price] = price if price.present?
            holding[:currency] = currency if currency.present?
            
            Rails.logger.debug("Adding holding: #{holding.inspect}")
            
            # Add to holdings
            holdings << holding
          rescue => e
            Rails.logger.error("Error processing line in manual parse: #{e.message}")
            Rails.logger.error("Problematic line: #{line}")
            next
          end
        end
        
        Rails.logger.info("Manually parsed #{holdings.size} holdings")
        
        # Log sample of holdings with price data
        with_price = holdings.select { |h| h[:price].present? }
        Rails.logger.info("Manual parsed holdings with price data: #{with_price.size}/#{holdings.size}")
        if with_price.any?
          sample = with_price.first(3)
          Rails.logger.info("Sample manually parsed holdings with price data:")
          sample.each do |h|
            Rails.logger.info("  #{h[:ticker] || h[:name]}: Price #{h[:price]} #{h[:currency]}")
          end
        else
          Rails.logger.warn("NO MANUALLY PARSED HOLDINGS HAVE PRICE DATA!")
        end
        
        holdings
      end
    end
  end
end 