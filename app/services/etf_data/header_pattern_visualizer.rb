require 'csv'

module EtfData
  class HeaderPatternVisualizer
    attr_reader :analysis_dir, :patterns
    
    def initialize(analysis_dir = nil)
      @analysis_dir = analysis_dir || Rails.root.join('tmp', 'csv_headers_analysis')
      @patterns = {}
      @pattern_frequencies = Hash.new(0)
    end
    
    def analyze
      unless Dir.exist?(@analysis_dir) && Dir.glob("#{@analysis_dir}/*.csv").any?
        Rails.logger.error("No CSV files found in #{@analysis_dir}")
        return false
      end
      
      # Track all unique fields across all patterns
      @all_fields = []
      @all_files = Dir.glob("#{@analysis_dir}/*.csv")
      
      # First pass: collect all header patterns
      @all_files.each do |file_path|
        extract_header_pattern(file_path)
      end
      
      # Sort patterns by frequency
      @patterns = @patterns.sort_by { |_, data| -data[:count] }.to_h
      
      true
    end
    
    def generate_visual_report
      output_file = Rails.root.join('tmp', 'csv_header_visual_comparison.html')
      
      File.open(output_file, 'w') do |file|
        file.puts <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>CSV Header Pattern Comparison</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 20px; }
              h1, h2 { color: #333; }
              table { border-collapse: collapse; width: 100%; margin-bottom: 30px; }
              th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
              th { background-color: #f2f2f2; position: sticky; top: 0; }
              tr:hover { background-color: #f5f5f5; }
              .pattern-header { background-color: #e0e0e0; font-weight: bold; }
              .match { background-color: #dff0d8; }
              .partial-match { background-color: #fcf8e3; }
              .no-match { background-color: #f2dede; }
              .pattern-meta { margin-bottom: 15px; }
              .pattern-meta span { margin-right: 15px; }
              .ticker-list { max-height: 100px; overflow-y: auto; margin-bottom: 10px; }
              .notes { background-color: #f8f9fa; padding: 10px; border-left: 4px solid #007bff; }
            </style>
          </head>
          <body>
            <h1>CSV Header Pattern Comparison</h1>
            <p>Generated at: #{Time.current}</p>
            <p>Total files analyzed: #{@all_files.size}</p>
            <p>Unique patterns found: #{@patterns.size}</p>
            
            <div class="notes">
              <p><strong>Notes:</strong></p>
              <ul>
                <li><strong>Green cells</strong>: Field names that match exactly across patterns</li>
                <li><strong>Yellow cells</strong>: Field names that may be similar but with different capitalization or spelling</li>
                <li><strong>Red cells</strong>: Missing fields in this pattern</li>
              </ul>
            </div>
            
            <h2>Pattern Summary</h2>
            <table>
              <tr>
                <th>Pattern #</th>
                <th>Count</th>
                <th>ETF Count</th>
                <th>Sample ETFs</th>
                <th>Sample File</th>
                <th>Header Row</th>
              </tr>
        HTML
        
        @patterns.each_with_index do |(key, pattern), idx|
          sample_tickers = pattern[:tickers].first(5).join(", ")
          if pattern[:tickers].size > 5
            sample_tickers += " and #{pattern[:tickers].size - 5} more"
          end
          
          file.puts <<~HTML
            <tr>
              <td>Pattern #{idx + 1}</td>
              <td>#{pattern[:count]} files</td>
              <td>#{pattern[:tickers].size} ETFs</td>
              <td>#{sample_tickers}</td>
              <td>#{pattern[:sample_file]}</td>
              <td>#{pattern[:row]}</td>
            </tr>
          HTML
        end
        
        file.puts "</table>"
        
        # Create a list of normalized field names across all patterns
        all_field_names = []
        @patterns.each do |_, pattern|
          pattern[:headers].each do |header|
            normalized = normalize_field_name(header.to_s)
            all_field_names << normalized unless all_field_names.include?(normalized)
          end
        end
        
        # Sort field names to group similar fields together
        all_field_names.sort!
        
        # Generate the detailed comparison table
        file.puts "<h2>Detailed Pattern Comparison</h2>"
        file.puts "<table>"
        
        # Header row with pattern numbers
        file.puts "<tr><th>Field Name</th>"
        @patterns.each_with_index do |(_, _), idx|
          file.puts "<th>Pattern #{idx + 1}</th>"
        end
        file.puts "</tr>"
        
        # For each potential field
        all_field_names.each do |field_name|
          file.puts "<tr>"
          file.puts "<td>#{field_name}</td>"
          
          # For each pattern, check if it has this field
          @patterns.each do |_, pattern|
            found = false
            actual_name = ""
            
            pattern[:headers].each do |header|
              if normalize_field_name(header.to_s) == field_name
                found = true
                actual_name = header.to_s
                break
              end
            end
            
            if found
              # Check if it's an exact match or just a normalized match
              if actual_name.downcase == field_name.downcase
                file.puts "<td class='match'>#{actual_name}</td>"
              else
                file.puts "<td class='partial-match'>#{actual_name}</td>"
              end
            else
              file.puts "<td class='no-match'>-</td>"
            end
          end
          
          file.puts "</tr>"
        end
        
        file.puts "</table>"
        
        # Add pattern details section
        file.puts "<h2>Pattern Details</h2>"
        
        @patterns.each_with_index do |(key, pattern), idx|
          file.puts <<~HTML
            <h3>Pattern #{idx + 1}</h3>
            <div class="pattern-meta">
              <span><strong>Files:</strong> #{pattern[:count]}</span>
              <span><strong>Delimiter:</strong> '#{pattern[:delimiter]}'</span>
              <span><strong>Sample file:</strong> #{pattern[:sample_file]}</span>
            </div>
            
            <div class="ticker-list">
              <strong>ETFs using this pattern (#{pattern[:tickers].size}):</strong> #{pattern[:tickers].join(', ')}
            </div>
            
            <h4>Headers:</h4>
            <table>
              <tr>
                <th>Index</th>
                <th>Header</th>
                <th>Suggested Mapping</th>
              </tr>
          HTML
          
          pattern[:headers].each_with_index do |header, hidx|
            header_str = header.to_s.strip
            suggested_mapping = suggest_mapping_for_header(header_str)
            
            file.puts <<~HTML
              <tr>
                <td>#{hidx}</td>
                <td>#{header_str}</td>
                <td>#{suggested_mapping}</td>
              </tr>
            HTML
          end
          
          file.puts "</table>"
        end
        
        # Complete the HTML
        file.puts <<~HTML
            <hr>
            <p><em>This report helps you identify common header patterns and differences between them.</em></p>
          </body>
          </html>
        HTML
      end
      
      Rails.logger.info("Visual header pattern comparison saved to #{output_file}")
      output_file
    end
    
    private
    
    def extract_header_pattern(file_path)
      filename = File.basename(file_path, '.csv')
      ticker = filename.split('_').first
      
      begin
        # Read file to analyze headers
        content = File.read(file_path, encoding: 'bom|utf-8')
        lines = content.lines.map(&:strip).reject(&:empty?)[0..20] # First 20 non-empty lines
        
        # Try to find header row
        header_row_index = find_header_row(lines)
        
        if header_row_index >= 0
          header_row = lines[header_row_index]
          
          # Parse header using correct delimiter
          delimiter = content.include?(';') ? ';' : ','
          begin
            headers = CSV.parse_line(header_row, col_sep: delimiter)
            
            if headers
              # Generate a key for this header pattern
              pattern_key = headers.map { |h| normalize_field_name(h.to_s) }.join('|')
              
              # Record pattern if it's new
              unless @patterns[pattern_key]
                @patterns[pattern_key] = {
                  headers: headers,
                  delimiter: delimiter,
                  count: 0,
                  tickers: [],
                  sample_file: filename,
                  row: header_row_index
                }
              end
              
              @patterns[pattern_key][:count] += 1
              @patterns[pattern_key][:tickers] << ticker unless @patterns[pattern_key][:tickers].include?(ticker)
            end
          rescue CSV::MalformedCSVError => e
            Rails.logger.error("Malformed CSV in #{filename}: #{e.message}")
          end
        end
      rescue => e
        Rails.logger.error("Error analyzing #{filename}: #{e.message}")
      end
    end
    
    def find_header_row(lines)
      lines.each_with_index do |line, idx|
        line_lower = line.downcase
        
        # Primary check
        if (line_lower.include?('ticker') || line_lower.include?('emittententicker')) && 
           (line_lower.include?('weight') || line_lower.include?('gewichtung') || line_lower.include?('name'))
          return idx
        end
        
        # Secondary check
        if line_lower.include?('name') && 
           (line_lower.include?('sektor') || line_lower.include?('sector') || 
            line_lower.include?('standort') || line_lower.include?('location'))
          return idx
        end
        
        # Tertiary check - enough header indicators
        header_indicators = ['name', 'ticker', 'weight', 'sector', 'class', 'location', 'price', 
                           'klasse', 'gewichtung', 'sektor', 'standort', 'preis']
        matches = header_indicators.count { |indicator| line_lower.include?(indicator) }
        if matches >= 3
          return idx
        end
      end
      
      -1
    end
    
    def normalize_field_name(name)
      return "" if name.nil?
      
      name = name.to_s.downcase.strip
      
      # Common field name normalizations
      case name
      when /^emittententicker$/, /^ticker$/
        "ticker"
      when /^name$/
        "name"
      when /^gewichtung/, /weight/, /%/
        "weight"
      when /^sektor$/, /^sector$/
        "sector"
      when /^asset/, /^klasse$/, /^class$/
        "asset_class"
      when /^standort$/, /^location$/, /^country$/
        "country"
      when /^preis$/, /^price$/
        "price"
      when /^währung$/, /^currency$/, /^marktwährung$/
        "currency"
      when /^maturity$/, /^fälligkeit$/
        "maturity"
      when /^coupon$/, /^kupon$/
        "coupon"
      when /^duration$/
        "duration"
      else
        name
      end
    end
    
    def suggest_mapping_for_header(header)
      header_lower = header.to_s.downcase
      
      if header_lower.match?(/ticker|emittententicker/)
        "ticker"
      elsif header_lower == "name"
        "name"
      elsif header_lower.match?(/weight|gewichtung|%/)
        "weight"
      elsif header_lower.match?(/sektor|sector/)
        "sector"
      elsif header_lower.match?(/asset|klasse|class/)
        "asset_class"
      elsif header_lower.match?(/standort|location|country/)
        "country"
      elsif header_lower.match?(/preis|price/)
        "price"
      elsif header_lower.match?(/währung|currency|marktwährung/)
        "currency"
      elsif header_lower.match?(/maturity|fälligkeit/)
        "maturity"
      elsif header_lower.match?(/coupon|kupon/)
        "coupon"
      elsif header_lower.match?(/duration/)
        "duration"
      else
        "-"
      end
    end
  end
end 