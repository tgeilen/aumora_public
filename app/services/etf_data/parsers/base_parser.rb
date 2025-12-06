require 'csv'

module EtfData
  module Parsers
    class BaseParser
      attr_reader :as_of_date
      
      def initialize
        @as_of_date = nil
      end
      
      # Template method for parsing that subclasses can override
      def parse(file_path)
        content = File.read(file_path, encoding: 'bom|utf-8')
        
        # Extract as_of_date from the file
        extract_as_of_date(content)
        
        # Default to today if we couldn't extract a date
        @as_of_date ||= Date.today
        
        # Initial parsing to determine the format
        csv_options = determine_csv_options(content)
        csv = parse_csv(file_path, csv_options)
        
        # Find the row with column headers
        header_row_index = find_header_row_index(csv)
        
        # Re-parse with headers at the correct position
        if header_row_index > 0
          csv_options[:headers] = header_row_index
          csv = parse_csv(file_path, csv_options)
        end
        
        # Map columns based on language
        column_mapping = determine_column_mapping(csv.headers)
        
        # Process holdings - specific to each subclass
        process_holdings(csv, column_mapping)
      end
      
      protected
      
      # Extract the as_of_date from the file content
      def extract_as_of_date(content)
        match = content.match(/(?:Fund Holdings as of|Fondsposition per)[\s,]*"([^"]+)"/)
        if match && match[1]
          @as_of_date = parse_date(match[1])
        end
      end
      
      # Default implementation that subclasses should override
      def process_holdings(csv, column_mapping)
        raise NotImplementedError, "#{self.class} must implement #process_holdings"
      end
      
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
          # Convert row to a string representation for easier searching
          row_values = row.to_h.values.join(' ').downcase
          
          # Debug log the row for troubleshooting
          Rails.logger.debug("Checking row #{index} for headers: #{row_values}")
          
          # Look for various header patterns that strongly indicate this is the header row
          if row_values.include?('ticker') && row_values.include?('weight') ||
             row_values.include?('emittententicker') && row_values.include?('gewichtung') ||
             (row_values.include?('name') && (row_values.include?('sektor') || row_values.include?('sector'))) ||
             (row_values.match?(/emittententicker|ticker/) && row_values.match?(/name/) && row_values.match?(/gewichtung|weight/))
            Rails.logger.info("Found header row at index #{index}: #{row_values}")
            return index
          end
        end
        
        # If we couldn't find a header row with confidence, look for a row with at least some known header names
        csv.each_with_index do |row, index|
          row_values = row.to_h.values.join(' ').downcase
          
          # If any row has at least 3 of these common column names, consider it the header
          header_indicators = ['name', 'ticker', 'emittententicker', 'sector', 'sektor', 'weight', 'gewichtung']
          matches = header_indicators.count { |indicator| row_values.include?(indicator) }
          
          if matches >= 3
            Rails.logger.info("Using row #{index} as header row based on partial matches: #{row_values}")
            return index
          end
        end
        
        # If still no match, try to find a row that has "Name" and at least one other common header
        csv.each_with_index do |row, index|
          row_values = row.to_h.values.join(' ').downcase
          
          if row_values.include?('name') && 
             (row_values.include?('ticker') || row_values.include?('sektor') || 
              row_values.include?('weight') || row_values.include?('gewichtung'))
            Rails.logger.info("Using row #{index} as header row based on name and one other match: #{row_values}")
            return index
          end
        end
        
        Rails.logger.warn("Could not find a header row with confidence, defaulting to row 0")
        0 # Default to first row if no header row found
      end
      
      def parse_csv(file_path, options = {})
        options = { headers: true, col_sep: ',' }.merge(options)
        
        begin
          # Read the file with UTF-8 encoding and process BOM if present
          content = File.read(file_path, encoding: 'bom|utf-8')
          
          # Log the first few lines of content for debugging
          Rails.logger.info("CSV Content Preview for #{file_path}:")
          content.lines.take(10).each_with_index do |line, index|
            Rails.logger.info("Line #{index + 1}: #{line.strip}")
          end
          
          # Check if there are any header-like strings in the content
          header_patterns = ['ticker', 'emittententicker', 'name', 'sektor', 'sector', 'gewichtung', 'weight']
          header_matches = header_patterns.select { |pattern| content.downcase.include?(pattern) }
          
          # If we found header patterns, log them
          if header_matches.any?
            Rails.logger.info("Found potential headers in content: #{header_matches.join(', ')}")
          else
            Rails.logger.warn("No standard headers found in content, parsing may be challenging")
          end
          
          # Try to parse the CSV with the provided options
          Rails.logger.info("Parsing CSV with options: #{options.inspect}")
          
          begin
            parsed_csv = CSV.parse(content, **options)
            
            # Check if parsing seems valid
            if parsed_csv.headers.present?
              Rails.logger.info("Successfully parsed CSV with headers: #{parsed_csv.headers.inspect}")
              
              # Check for empty or suspicious headers
              if parsed_csv.headers.any? { |h| h.nil? || h.to_s.strip.empty? }
                Rails.logger.warn("CSV has nil or empty headers, which may cause issues later")
              end
              
              # Log the first few rows after headers for verification
              Rails.logger.debug("First rows of CSV data:")
              parsed_csv.first(3).each_with_index do |row, idx|
                Rails.logger.debug("  Row #{idx + 1}: #{row.to_h.inspect}")
              end
            else
              Rails.logger.warn("CSV parsed but has no headers")
            end
            
            parsed_csv
          rescue CSV::MalformedCSVError => e
            # If standard parsing fails, try with liberal parsing
            Rails.logger.warn("Malformed CSV, trying liberal parsing: #{e.message}")
            parsed_csv = CSV.parse(content, **options, liberal_parsing: true)
            
            if parsed_csv.headers.present?
              Rails.logger.info("Successfully parsed CSV with liberal parsing. Headers: #{parsed_csv.headers.inspect}")
            else
              Rails.logger.warn("CSV parsed with liberal parsing but has no headers")
            end
            
            parsed_csv
          end
        rescue => e
          Rails.logger.error("Failed to parse CSV file #{file_path}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          []
        end
      end
      
      def parse_date(date_str)
        return nil unless date_str.present?
        
        # Handle different date formats
        date_formats = [
          '%d.%b.%Y',   # 21.Apr.2025
          '%b %d, %Y',  # Apr 21, 2025
          '%Y-%m-%d'    # 2025-04-21
        ]
        
        date_formats.each do |format|
          begin
            return Date.strptime(date_str, format)
          rescue
            next
          end
        end
        
        # If all formats fail, try to parse with Date.parse
        begin
          Date.parse(date_str)
        rescue
          nil
        end
      end
      
      def normalize_sector(sector)
        return nil unless sector.present?
        
        # Map from sector abbreviations to full names
        sector_mapping = {
          'IT' => 'Information Technology',
          'COMM' => 'Communication Services',
          'COMMUN SVC' => 'Communication Services',
          'CONS DISC' => 'Consumer Discretionary',
          'CONS STAP' => 'Consumer Staples',
          'HEALTH' => 'Healthcare',
          'FIN' => 'Financials',
          'INDU' => 'Industrials',
          'INDUSTR' => 'Industrials',
          'TECH' => 'Information Technology',
          'MAT' => 'Materials',
          'MATERIALS' => 'Materials',
          'ENERGY' => 'Energy',
          'REAL EST' => 'Real Estate',
          'UTILITY' => 'Utilities',
          'UTIL' => 'Utilities'
        }
        
        return sector_mapping[sector.upcase] || sector
      end
      
      def determine_asset_type(asset_class)
        return nil unless asset_class.present?
        
        asset_class = asset_class.downcase
        
        if asset_class.include?('equity') || asset_class.include?('stock') || asset_class.include?('aktie')
          'equity'
        elsif asset_class.include?('bond') || asset_class.include?('fixed income') || asset_class.include?('anleihe')
          'bond'
        elsif asset_class.include?('cash') || asset_class.include?('money market') || asset_class.include?('geldmarkt')
          'cash'
        elsif asset_class.include?('commodity') || asset_class.include?('commodities') || asset_class.include?('rohstoff')
          'commodity'
        elsif asset_class.include?('real estate') || asset_class.include?('immobilien')
          'real_estate'
        else
          'other'
        end
      end
      
      def normalize_country(country)
        return nil unless country.present?
        
        # Mapping from German to English country names and common abbreviations
        country_mapping = {
          'USA' => 'United States',
          'US' => 'United States',
          'UK' => 'United Kingdom',
          'GB' => 'United Kingdom',
          'FR' => 'France',
          'DE' => 'Germany',
          'IT' => 'Italy',
          'JP' => 'Japan',
          'CH' => 'Switzerland',
          'SE' => 'Sweden',
          'DEUTSCHLAND' => 'Germany',
          'FRANKREICH' => 'France',
          'VEREINIGTES KÖNIGREICH' => 'United Kingdom',
          'VEREINIGTE STAATEN VON AMERIKA' => 'United States'
        }
        
        return country_mapping[country.upcase] || country
      end
      
      def extract_percentage(percentage_str)
        return nil unless percentage_str.present?
        
        # Clean the string and convert to decimal
        percentage_str = percentage_str.to_s.strip
        
        # Remove any % signs and spaces
        percentage_str = percentage_str.gsub(/[%\s]/, '')
        
        # Handle German number format (comma as decimal separator)
        # Convert last comma to dot, remove any other commas (thousand separators)
        if percentage_str.count(',') > 0
          last_comma_index = percentage_str.rindex(',')
          percentage_str = percentage_str.gsub(',', '')
          percentage_str = percentage_str.insert(last_comma_index, '.')
        end
        
        # Convert to float and divide by 100 to get decimal
        percentage_str.to_f / 100.0
      rescue
        Rails.logger.error("Failed to parse percentage: #{percentage_str}")
        0.0
      end
      
      def is_sector_summary(ticker, name)
        # Check if this is a summary row for a sector, which we want to skip
        return true if ticker.blank? || name.blank?
        
        sector_indicators = [
          'sector subtotal', 'sektor zwischensumme', 'total', 'gesamt',
          'subtotal', 'zwischensumme', 'summe', 'summary'
        ]
        
        name_downcase = name.downcase
        sector_indicators.any? { |indicator| name_downcase.include?(indicator) }
      end
      
      def determine_column_mapping(headers)
        # Convert headers to strings for comparison
        headers = headers.map(&:to_s)
        
        # Log headers for debugging
        Rails.logger.info("Determining column mapping for headers: #{headers.inspect}")
        
        # Initialize the column mapping hash
        mapping = {}
        
        # Map headers - check for both English and German variations
        headers.each do |header|
          header_downcase = header.downcase
          
          # Ticker
          if header_downcase == 'ticker' || header_downcase == 'emittententicker'
            mapping[:ticker] = header
          
          # Name
          elsif header_downcase == 'name'
            mapping[:name] = header
          
          # Sector
          elsif header_downcase == 'sector' || header_downcase == 'sektor'
            mapping[:sector] = header
          
          # Asset Class
          elsif header_downcase == 'asset class' || header_downcase == 'anlageklasse'
            mapping[:asset_class] = header
          
          # Weight
          elsif header_downcase.include?('weight') || header_downcase.include?('gewichtung') || header_downcase.include?('(%)') 
            mapping[:weight] = header
          
          # Country/Location
          elsif header_downcase == 'location' || header_downcase == 'standort'
            mapping[:country] = header
          
          # Bond duration
          elsif header_downcase == 'duration'
            mapping[:duration] = header
          
          # Bond maturity
          elsif header_downcase == 'maturity' || header_downcase == 'fälligkeit'
            mapping[:maturity] = header
          
          # Bond coupon
          elsif header_downcase == 'coupon' || header_downcase == 'kupon'
            mapping[:coupon] = header
          
          # Price information - NEW
          elsif header_downcase == 'price' || header_downcase == 'kurs'
            mapping[:price] = header
          
          # Currency information - NEW
          elsif header_downcase == 'currency' || header_downcase == 'marktwährung'
            mapping[:currency] = header
          end
        end
        
        # Log the mapping
        Rails.logger.info("Column mapping: #{mapping.inspect}")
        
        mapping
      end
    end
  end
end 