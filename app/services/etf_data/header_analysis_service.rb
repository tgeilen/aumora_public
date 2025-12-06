require 'csv'

module EtfData
  class HeaderAnalysisService
    attr_reader :analysis_dir, :results
    
    def initialize(analysis_dir = nil)
      @analysis_dir = analysis_dir || Rails.root.join('tmp', 'csv_headers_analysis')
      @results = {}
    end
    
    def analyze
      unless Dir.exist?(@analysis_dir) && Dir.glob("#{@analysis_dir}/*.csv").any?
        Rails.logger.error("No CSV files found in #{@analysis_dir}")
        return false
      end
      
      Rails.logger.info("Analyzing CSV headers from #{Dir.glob("#{@analysis_dir}/*.csv").count} files...")
      
      # Store file info by ticker
      @files_by_ticker = {}
      
      # First group files by ticker
      Dir.glob("#{@analysis_dir}/*.csv").each do |file_path|
        filename = File.basename(file_path, '.csv')
        ticker = filename.split('_').first
        
        @files_by_ticker[ticker] ||= []
        @files_by_ticker[ticker] << file_path
      end
      
      # Then analyze each ticker's files
      @files_by_ticker.each do |ticker, files|
        analyze_ticker_files(ticker, files)
      end
      
      true
    end
    
    def generate_report
      output_file = Rails.root.join('tmp', 'csv_header_analysis_detailed.txt')
      
      File.open(output_file, 'w') do |file|
        file.puts "CSV Header Detailed Analysis Report"
        file.puts "=================================="
        file.puts "Generated at: #{Time.current}"
        file.puts "Total ETFs analyzed: #{@results.keys.count}"
        file.puts "\n"
        
        @results.each do |ticker, data|
          file.puts "ETF: #{ticker}"
          file.puts "  Files analyzed: #{data[:file_count]}"
          file.puts "  Header positions: #{data[:header_positions].inspect}"
          file.puts "  Variant count: #{data[:variants].size}"
          file.puts "\n"
          
          # Problematic files
          if data[:problematic_files].any?
            file.puts "  Problematic files (#{data[:problematic_files].size}):"
            data[:problematic_files].each do |prob_file|
              file.puts "    - #{File.basename(prob_file[:file])}: #{prob_file[:issue]}"
            end
            file.puts "\n"
          end
          
          # Header variants
          file.puts "  Header variants:"
          data[:variants].each_with_index do |variant, idx|
            file.puts "    Variant #{idx+1} (#{variant[:occurrences]} files, row #{variant[:row]}):"
            file.puts "      Delimiter: '#{variant[:delimiter]}'"
            file.puts "      Sample file: #{variant[:sample_file]}"
            
            if variant[:headers]
              file.puts "      Headers (#{variant[:headers].size}):"
              variant[:headers].each_with_index do |header, hidx|
                file.puts "        #{hidx}: '#{header}'"
              end
            else
              file.puts "      No headers found"
            end
            file.puts ""
          end
          
          # Parser match summary
          parser_type = determine_parser_type(ticker)
          file.puts "  Recommended parser: #{parser_type}"
          
          if data[:variants].size > 0 && data[:variants][0][:headers]
            file.puts "  Column mapping recommendation:"
            
            mapping = suggest_column_mapping(data[:variants][0][:headers])
            mapping.each do |key, value|
              file.puts "    #{key}: #{value.inspect}"
            end
          end
          
          file.puts "\n"
          file.puts "------------------------------------------------------"
          file.puts "\n"
        end
        
        # Overall recommendations
        file.puts "Overall Recommendations"
        file.puts "======================="
        
        header_positions = count_header_positions
        if header_positions.keys.count > 1
          file.puts "Multiple header positions detected across files:"
          header_positions.sort_by { |position, count| -count }.each do |position, count|
            file.puts "  Row #{position}: #{count} files (#{(count.to_f/header_positions.values.sum*100).round(1)}%)"
          end
          file.puts "\nConsider enhancing the header detection logic to handle these variations."
        else
          file.puts "Header position is consistent (row #{header_positions.keys.first})."
        end
        
        inconsistent_tickers = @results.select { |_, data| data[:variants].size > 1 }
        if inconsistent_tickers.any?
          file.puts "\nThe following ETFs have inconsistent header formats:"
          inconsistent_tickers.keys.each do |ticker|
            file.puts "  - #{ticker} (#{@results[ticker][:variants].size} variants)"
          end
          file.puts "\nConsider implementing ETF-specific header handling for these tickers."
        end
      end
      
      Rails.logger.info("Detailed analysis saved to #{output_file}")
      output_file
    end
    
    def generate_parser_suggestions
      output_file = Rails.root.join('tmp', 'suggested_column_mappings.rb')
      
      File.open(output_file, 'w') do |file|
        file.puts "# Generated Parser Suggestions"
        file.puts "# =========================="
        file.puts "# Generated at: #{Time.current}"
        file.puts "# This file contains suggested column mapping code for different header variants"
        file.puts "# Copy relevant sections to your parser implementations"
        file.puts "\n"
        
        @results.each do |ticker, data|
          next unless data[:variants].any? && data[:variants][0][:headers]
          
          file.puts "# #{ticker} - #{data[:variants].size} variant(s)"
          file.puts "# Files analyzed: #{data[:file_count]}"
          
          # For each variant, generate mapping code
          data[:variants].each_with_index do |variant, idx|
            headers = variant[:headers]
            
            file.puts "# Variant #{idx+1} (found in #{variant[:occurrences]} files, header at row #{variant[:row]})"
            file.puts "# Sample file: #{variant[:sample_file]}"
            file.puts "# Headers: #{headers.inspect}"
            
            mapping = suggest_column_mapping(headers)
            
            if mapping.any?
              file.puts "\n# Suggested column mapping code:"
              file.puts "def determine_column_mapping(headers)"
              file.puts "  # Column mapping for #{ticker} - Variant #{idx+1}"
              file.puts "  if headers && ["
              
              # Generate a condition to identify this header pattern
              sample_headers = headers.compact.sample([3, headers.compact.size].min)
              sample_headers.each do |header|
                file.puts "    headers.include?(#{header.inspect})," 
              end
              
              file.puts "  ].all?"
              file.puts "    # This handles the #{ticker} header format"
              file.puts "    return {"
              
              # Generate the mapping hash
              mapping.each do |key, value|
                if headers[value]
                  file.puts "      #{key}: headers.find { |h| h.to_s.downcase == #{headers[value].to_s.downcase.inspect} },"
                end
              end
              
              file.puts "    }"
              file.puts "  end"
              file.puts "  # Fall back to default mapping if headers don't match"
              file.puts "  # ..."
              file.puts "end"
            end
            
            file.puts "\n# Alternative direct index access:"
            file.puts "# Based on header position (for direct CSV parsing):"
            mapping.each do |key, value|
              file.puts "# #{key} = row[#{value}] # '#{headers[value]}'"
            end
            
            file.puts "\n# ========================================"
          end
          
          file.puts "\n\n"
        end
      end
      
      Rails.logger.info("Parser suggestions saved to #{output_file}")
      output_file
    end
    
    private
    
    def analyze_ticker_files(ticker, files)
      result = {
        file_count: files.size,
        header_positions: Hash.new(0),
        variants: [],
        variant_keys: {},
        problematic_files: []
      }
      
      files.each do |file_path|
        begin
          # Read file
          content = File.read(file_path, encoding: 'bom|utf-8')
          lines = content.lines.map(&:strip).reject(&:empty?)[0..30] # Analyze first 30 non-empty lines
          
          # Try to find header row
          header_row_index = find_header_row(lines)
          
          if header_row_index >= 0
            # Record header position
            result[:header_positions][header_row_index] += 1
            header_row = lines[header_row_index]
            
            # Parse header with correct delimiter
            delimiter = content.include?(';') ? ';' : ','
            begin
              headers = CSV.parse_line(header_row, col_sep: delimiter)
              
              # Generate a unique key for this header variant
              variant_key = headers.map(&:to_s).join('|')
              
              # Check if we've seen this variant before
              if result[:variant_keys][variant_key]
                variant_idx = result[:variant_keys][variant_key]
                result[:variants][variant_idx][:occurrences] += 1
              else
                # Add new variant
                variant_idx = result[:variants].size
                result[:variant_keys][variant_key] = variant_idx
                
                result[:variants] << {
                  headers: headers,
                  delimiter: delimiter,
                  row: header_row_index,
                  occurrences: 1,
                  sample_file: File.basename(file_path)
                }
              end
            rescue CSV::MalformedCSVError => e
              result[:problematic_files] << {
                file: file_path,
                issue: "Malformed CSV: #{e.message}"
              }
            end
          else
            result[:problematic_files] << {
              file: file_path,
              issue: "No header row detected"
            }
          end
        rescue => e
          result[:problematic_files] << {
            file: file_path,
            issue: "Error: #{e.message}"
          }
        end
      end
      
      # Sort variants by occurrence (most common first)
      result[:variants].sort_by! { |v| -v[:occurrences] }
      
      @results[ticker] = result
    end
    
    def find_header_row(lines)
      # Look for common header patterns
      lines.each_with_index do |line, idx|
        line_lower = line.downcase
        
        # Primary check - strong header indicators
        if (line_lower.include?('ticker') || line_lower.include?('emittententicker')) && 
           (line_lower.include?('weight') || line_lower.include?('gewichtung'))
          return idx
        end
        
        # Secondary check - other common patterns
        if line_lower.include?('name') && 
           (line_lower.include?('sektor') || line_lower.include?('sector') || 
            line_lower.include?('standort') || line_lower.include?('location'))
          return idx
        end
        
        # Third check - enough potential header columns
        header_indicators = ['name', 'ticker', 'weight', 'sector', 'class', 'location', 'price', 
                            'klasse', 'gewichtung', 'sektor', 'standort', 'preis']
        matches = header_indicators.count { |indicator| line_lower.include?(indicator) }
        if matches >= 3
          return idx
        end
      end
      
      # No header found
      -1
    end
    
    def count_header_positions
      positions = Hash.new(0)
      
      @results.each do |_, data|
        data[:header_positions].each do |pos, count|
          positions[pos] += count
        end
      end
      
      positions
    end
    
    def determine_parser_type(ticker)
      # Try to determine if this is a bond ETF based on ticker or variant content
      bond_keywords = ['bond', 'treasury', 'govt', 'corporate', 'yield', 'duration', 'anleihe']
      
      # Check ticker name
      is_bond = bond_keywords.any? { |keyword| ticker.downcase.include?(keyword) }
      
      # Check header content if available
      unless is_bond
        ticker_data = @results[ticker]
        if ticker_data && ticker_data[:variants].any? && ticker_data[:variants][0][:headers]
          headers = ticker_data[:variants][0][:headers].map(&:to_s).join(' ').downcase
          is_bond = bond_keywords.any? { |keyword| headers.include?(keyword) }
          
          # Also check for bond-specific headers
          is_bond ||= headers.include?('maturity') || headers.include?('coupon') || 
                      headers.include?('duration') || headers.include?('yield')
        end
      end
      
      is_bond ? 'IsharesBondParser' : 'IsharesEquityParser'
    end
    
    def suggest_column_mapping(headers)
      headers = headers.map { |h| h.to_s.downcase }
      
      mapping = {}
      
      # Map standard fields
      headers.each_with_index do |header, idx|
        case header
        when /ticker|emittententicker/
          mapping[:ticker] = idx
        when /^name$/
          mapping[:name] = idx
        when /weight|gewichtung|%/
          mapping[:weight] = idx
        when /sektor|sector/
          mapping[:sector] = idx
        when /asset|klasse|class/
          mapping[:asset_class] = idx
        when /standort|location|country/
          mapping[:country] = idx
        when /^preis$|^price$/
          mapping[:price] = idx
        when /währung|currency|marktwährung/
          mapping[:currency] = idx
        when /maturity|fälligkeit/
          mapping[:maturity] = idx
        when /coupon|kupon/
          mapping[:coupon] = idx
        when /duration/
          mapping[:duration] = idx
        end
      end
      
      mapping
    end
  end
end 