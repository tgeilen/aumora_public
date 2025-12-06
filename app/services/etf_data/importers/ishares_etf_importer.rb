require 'creek'
require 'nokogiri'

module EtfData
  module Importers
    class IsharesEtfImporter
      attr_reader :file_path, :provider

      def initialize(file_path, provider = nil)
        @file_path = file_path
        @provider = provider || find_or_create_provider
      end

      def import
        Rails.logger.info("Importing ETFs from #{file_path}")
        puts "Reading file: #{file_path}"
        
        # Try to use creek first
        begin
          return import_with_creek
        rescue => e
          puts "Creek parsing failed: #{e.message}"
          Rails.logger.error("Creek parsing failed: #{e.message}")
          # Fall back to Nokogiri XML parsing
          return import_with_nokogiri
        end
      end

      private
      
      def import_with_creek
        workbook = Creek::Book.new(file_path)
        puts "Opened workbook with #{workbook.sheets.count} sheets"
        
        sheet = workbook.sheets.first
        etfs_imported = []
        
        # Find the header row and identify columns
        headers = {}
        header_row_index = nil
        
        sheet.simple_rows.each_with_index do |row, index|
          puts "Row #{index}: #{row.values.join(' ')}" if index < 5
          
          # Look for key column names in the row
          row_values = row.values.join(' ').downcase
          if row_values.include?('isin') && (row_values.include?('ticker') || row_values.include?('symbol'))
            header_row_index = index
            headers = identify_columns(row)
            puts "Found header row at index #{index}: #{headers}"
            break
          end
        end
        
        unless header_row_index && headers[:ticker] && headers[:name] && headers[:isin]
          Rails.logger.error("Could not find required columns in the XLS file")
          return []
        end
        
        # Process data rows
        sheet.simple_rows.drop(header_row_index + 1).each_with_index do |row, index|
          
          # Extract data from row using identified columns
          ticker = row[headers[:ticker]]
          name = row[headers[:name]]
          isin = row[headers[:isin]]
          asset_class = row[headers[:asset_class]] if headers[:asset_class]
          
          puts "Processing row: Ticker=#{ticker}, Name=#{name}, ISIN=#{isin}"
          
          # Skip if any required field is missing
          next unless ticker.present? && name.present? && isin.present?
          
          # Create or update ETF
          metadata = {
            isin: isin,
            imported_at: Time.current
          }
          
          # Add asset class if available
          metadata[:asset_class] = asset_class if asset_class.present?
          
          etf = import_etf(ticker, name, metadata)
          etfs_imported << etf if etf.present?
        end
        
        puts "Imported #{etfs_imported.size} ETFs with Creek"
        etfs_imported
      end
      
      def import_with_nokogiri
        puts "Attempting to parse with Nokogiri XML"
        
        doc = Nokogiri::XML(File.open(file_path))
        rows = doc.xpath('//ss:Row', 'ss' => 'urn:schemas-microsoft-com:office:spreadsheet')
        puts "Found #{rows.count} rows in XML"
        
        # Find the header row
        header_row = nil
        header_index = nil
        
        rows.each_with_index do |row, index|
          cells = row.xpath('.//ss:Cell/ss:Data', 'ss' => 'urn:schemas-microsoft-com:office:spreadsheet')
          cell_values = cells.map(&:text).join(' ').downcase
          
          puts "Row #{index}: #{cell_values}" if index < 5
          
          if cell_values.include?('isin') && (cell_values.include?('ticker') || cell_values.include?('symbol'))
            header_row = row
            header_index = index
            break
          end
        end
        
        return [] unless header_row
        
        puts "Found header row at index #{header_index}"
        
        # Extract header column positions
        headers = {}
        header_cells = header_row.xpath('.//ss:Cell', 'ss' => 'urn:schemas-microsoft-com:office:spreadsheet')
        
        header_cells.each_with_index do |cell, index|
          cell_value = cell.at_xpath('./ss:Data', 'ss' => 'urn:schemas-microsoft-com:office:spreadsheet')&.text&.downcase
          next unless cell_value
          
          if cell_value.include?('ticker') || cell_value.include?('symbol')
            headers[:ticker] = index
          elsif cell_value.include?('name') || cell_value.include?('bezeichnung')
            headers[:name] = index
          elsif cell_value.include?('isin')
            headers[:isin] = index
          elsif cell_value.include?('asset') || cell_value.include?('klasse')
            headers[:asset_class] = index
          end
        end
        
        puts "Identified headers: #{headers}"
        
        unless headers[:ticker] && headers[:name] && headers[:isin]
          puts "Required columns not found"
          return []
        end
        
        # Process data rows
        etfs_imported = []
        rows.drop(header_index + 1).each_with_index do |row, index|
         
          
          cells = row.xpath('.//ss:Cell/ss:Data', 'ss' => 'urn:schemas-microsoft-com:office:spreadsheet')
          
          # Extract cell values
          ticker = cells[headers[:ticker]]&.text
          name = cells[headers[:name]]&.text
          isin = cells[headers[:isin]]&.text
          asset_class = headers[:asset_class] ? cells[headers[:asset_class]]&.text : nil
          
          puts "Processing row: Ticker=#{ticker}, Name=#{name}, ISIN=#{isin}"
          
          # Skip if any required field is missing
          next unless ticker.present? && name.present? && isin.present?
          
          # Create or update ETF
          metadata = {
            isin: isin,
            imported_at: Time.current
          }
          
          # Add asset class if available
          metadata[:asset_class] = asset_class if asset_class.present?
          
          etf = import_etf(ticker, name, metadata)
          etfs_imported << etf if etf.present?
        end
        
        puts "Imported #{etfs_imported.size} ETFs with Nokogiri"
        etfs_imported
      end
      
      def identify_columns(row)
        headers = {}
        
        row.each do |key, value|
          next unless value
          value = value.to_s.downcase
          
          if value.include?('ticker') || value.include?('symbol')
            headers[:ticker] = key
          elsif value.include?('name') || value.include?('bezeichnung')
            headers[:name] = key
          elsif value.include?('isin')
            headers[:isin] = key
          elsif value.include?('asset') || value.include?('klasse')
            headers[:asset_class] = key
          end
        end
        
        headers
      end

      def find_or_create_provider
        EtfProvider.find_or_create_by!(name: 'iShares') do |provider|
          provider.base_url = 'https://www.ishares.com'
          provider.data_format = 'csv'
          provider.url_pattern = 'https://www.ishares.com/{{country}}/{{investor_type}}/{{language}}/produkte/{{product_id}}/{{ticker}}'
          provider.parser_configuration = {
            csv_link_selector: '.holdings.fund-component-data-export a.icon-xls-export'
          }
        end
      end

      def import_etf(ticker, name, metadata = {})
        etf = Etf.find_or_initialize_by(
          ticker: ticker,
          provider: provider
        )
        
        # Update attributes
        etf.name = name
        
        # Merge existing metadata with new metadata
        existing_metadata = etf.formatted_metadata
        etf.metadata = existing_metadata.merge(metadata)
        
        if etf.save
          puts "Imported ETF: #{ticker} - #{name}"
          etf
        else
          puts "Failed to save ETF #{ticker}: #{etf.errors.full_messages.join(', ')}"
          nil
        end
      end
    end
  end
end 