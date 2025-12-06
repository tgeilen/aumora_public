require 'csv'

namespace :etf_data do
  desc "Import iShares ETFs from XLS file"
  task import_ishares_etfs: :environment do
    file_path = Rails.root.join('db', 'seed_data', 'iShares-Germany.xls')
    
    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end
    
    puts "Importing iShares ETFs from #{file_path}..."
    
    importer = EtfData::Importers::IsharesEtfImporter.new(file_path)
    etfs = importer.import
    
    puts "Successfully imported #{etfs.size} ETFs"
  end
  
  desc "Import ETF holdings from sample CSV files"
  task import_sample_holdings: :environment do
    sample_dir = Rails.root.join('tmp', 'sample_data')
    
    # Check if the directory exists and contains CSV files
    unless Dir.exist?(sample_dir) && Dir.glob("#{sample_dir}/*.csv").any?
      puts "Error: No CSV files found in #{sample_dir}"
      exit 1
    end
    
    # Find or create iShares provider
    provider = EtfProvider.find_or_create_by!(
      name: 'iShares',
      base_url: 'https://www.ishares.com',
      data_format: 'csv',
      url_pattern: 'https://www.ishares.com/{{country}}/{{investor_type}}/{{language}}/produkte/{{product_id}}/{{ticker}}',
      parser_configuration: {
        csv_link_selector: '.holdings.fund-component-data-export a.icon-xls-export'
      }
    )
    
    # Create the ETF data fetch job
    job = EtfDataFetchJob.new
    
    # Process each CSV file
    success_count = 0
    Dir.glob("#{sample_dir}/*.csv").each do |csv_file|
      filename = File.basename(csv_file, '.csv')
      ticker = filename.split('_').first
      
      puts "Processing holdings for ETF #{ticker}..."
      if job.process_holdings_file(ticker, csv_file, 'iShares')
        success_count += 1
      end
    end
    
    puts "Successfully processed #{success_count} ETF holdings files"
  end
  
  desc "Process a single ETF holdings file"
  task :process_holdings_file, [:ticker, :file_path] => :environment do |t, args|
    if args[:ticker].blank? || args[:file_path].blank? || !File.exist?(args[:file_path])
      puts "Usage: rake etf_data:process_holdings_file[TICKER,FILE_PATH]"
      puts "Example: rake etf_data:process_holdings_file[EUNL,/path/to/EUNL_holdings.csv]"
      exit 1
    end
    
    job = EtfDataFetchJob.new
    if job.process_holdings_file(args[:ticker], args[:file_path])
      puts "Successfully processed holdings for ETF #{args[:ticker]}"
    else
      puts "Failed to process holdings for ETF #{args[:ticker]}"
      exit 1
    end
  end
  
  desc "Analyze CSV header structure from saved files"
  task analyze_csv_headers: :environment do
    analysis_dir = Rails.root.join('tmp', 'csv_headers_analysis')
    
    unless Dir.exist?(analysis_dir) && Dir.glob("#{analysis_dir}/*.csv").any?
      puts "Error: No CSV files found in #{analysis_dir}"
      exit 1
    end
    
    puts "Analyzing CSV headers from #{Dir.glob("#{analysis_dir}/*.csv").count} files..."
    
    # Store results for each ticker
    results = {}
    
    Dir.glob("#{analysis_dir}/*.csv").each do |file_path|
      filename = File.basename(file_path, '.csv')
      ticker = filename.split('_').first
      
      puts "Analyzing headers for #{filename}..."
      
      # Initialize ticker entry if not exists
      results[ticker] ||= {
        files_analyzed: 0,
        header_variants: {},
        header_positions: Hash.new(0)
      }
      
      begin
        # Read file to analyze headers
        content = File.read(file_path, encoding: 'bom|utf-8')
        lines = content.lines.map(&:strip).reject(&:empty?)[0..20] # Analyze first 20 non-empty lines
        
        # Try to find header row
        header_row_index = -1
        header_row = nil
        
        lines.each_with_index do |line, idx|
          if line.downcase.include?('ticker') && 
             (line.downcase.include?('weight') || 
              line.downcase.include?('gewichtung') ||
              line.downcase.include?('name'))
            header_row_index = idx
            header_row = line
            break
          end
        end
        
        if header_row_index >= 0
          # Record header position stats
          results[ticker][:header_positions][header_row_index] += 1
          results[ticker][:files_analyzed] += 1
          
          # Parse header using correct delimiter
          delimiter = content.include?(';') ? ';' : ','
          headers = CSV.parse_line(header_row, col_sep: delimiter)
          
          # Generate a unique key for this header variant
          header_key = headers.map(&:to_s).join('|')
          
          # Record header variant
          results[ticker][:header_variants][header_key] ||= {
            headers: headers,
            delimiter: delimiter,
            count: 0,
            sample_filename: filename
          }
          results[ticker][:header_variants][header_key][:count] += 1
        else
          puts "  No header row found in #{filename}"
        end
      rescue => e
        puts "  Error analyzing #{filename}: #{e.message}"
      end
    end
    
    # Output summary report
    output_file = Rails.root.join('tmp', 'csv_header_analysis_report.txt')
    
    File.open(output_file, 'w') do |file|
      file.puts "CSV Header Analysis Report"
      file.puts "=========================="
      file.puts "Generated at: #{Time.current}"
      file.puts "Total ETFs analyzed: #{results.keys.count}"
      file.puts "\n"
      
      # For each ticker, report findings
      results.each do |ticker, data|
        file.puts "ETF: #{ticker}"
        file.puts "  Files analyzed: #{data[:files_analyzed]}"
        file.puts "  Header positions:"
        
        data[:header_positions].sort.each do |position, count|
          file.puts "    Row #{position}: #{count} files (#{(count.to_f/data[:files_analyzed]*100).round(1)}%)"
        end
        
        file.puts "  Header variants (#{data[:header_variants].size}):"
        
        data[:header_variants].each_with_index do |(key, variant), idx|
          file.puts "    Variant #{idx+1}: Found in #{variant[:count]} files (#{(variant[:count].to_f/data[:files_analyzed]*100).round(1)}%)"
          file.puts "      Delimiter: '#{variant[:delimiter]}'"
          file.puts "      Sample file: #{variant[:sample_filename]}"
          file.puts "      Headers: "
          variant[:headers].each_with_index do |header, header_idx|
            header_str = header.to_s.strip
            file.puts "        #{header_idx}: '#{header_str}'"
          end
          file.puts ""
        end
        
        file.puts "\n"
      end
    end
    
    puts "Analysis complete! Report saved to: #{output_file}"
  end
  
  desc "Generate detailed CSV header structure analysis"
  task analyze_headers_detailed: :environment do
    puts "Starting detailed CSV header analysis..."
    
    service = EtfData::HeaderAnalysisService.new
    if service.analyze
      report_path = service.generate_report
      puts "Detailed analysis complete! Report saved to: #{report_path}"
    else
      puts "Analysis failed - no CSV files found"
    end
  end
  
  desc "Generate parser code suggestions for CSV headers"
  task generate_parser_suggestions: :environment do
    puts "Generating parser suggestions from CSV header analysis..."
    
    service = EtfData::HeaderAnalysisService.new
    if service.analyze
      suggestions_path = service.generate_parser_suggestions
      puts "Parser suggestions generated! File saved to: #{suggestions_path}"
    else
      puts "Analysis failed - no CSV files found"
    end
  end
  
  desc "Summarize unique header combinations across all ETFs"
  task summarize_header_patterns: :environment do
    puts "Analyzing CSV headers for unique patterns..."
    
    analysis_dir = Rails.root.join('tmp', 'csv_headers_analysis')
    
    unless Dir.exist?(analysis_dir) && Dir.glob("#{analysis_dir}/*.csv").any?
      puts "Error: No CSV files found in #{analysis_dir}"
      exit 1
    end
    
    # Store unique header patterns
    unique_patterns = {}
    file_counts = Hash.new(0)
    
    # Process each file
    Dir.glob("#{analysis_dir}/*.csv").each do |file_path|
      filename = File.basename(file_path, '.csv')
      ticker = filename.split('_').first
      file_counts[ticker] += 1
      
      begin
        # Read file to analyze headers
        content = File.read(file_path, encoding: 'bom|utf-8')
        lines = content.lines.map(&:strip).reject(&:empty?)[0..20] # Analyze first 20 non-empty lines
        
        # Try to find header row
        header_row_index = -1
        header_row = nil
        
        lines.each_with_index do |line, idx|
          if line.downcase.include?('ticker') && 
             (line.downcase.include?('weight') || 
              line.downcase.include?('gewichtung') ||
              line.downcase.include?('name'))
            header_row_index = idx
            header_row = line
            break
          end
        end
        
        if header_row_index >= 0
          # Parse header using correct delimiter
          delimiter = content.include?(';') ? ';' : ','
          headers = CSV.parse_line(header_row, col_sep: delimiter)
          
          if headers
            # Generate a unique key for this header pattern
            header_key = headers.map { |h| h.to_s.downcase }.join('|')
            
            # Record unique pattern
            unless unique_patterns[header_key]
              unique_patterns[header_key] = {
                headers: headers,
                delimiter: delimiter,
                count: 0,
                tickers: []
              }
            end
            
            unique_patterns[header_key][:count] += 1
            unique_patterns[header_key][:tickers] << ticker unless unique_patterns[header_key][:tickers].include?(ticker)
          end
        end
      rescue => e
        puts "  Error analyzing #{filename}: #{e.message}"
      end
    end
    
    # Output summary report
    output_file = Rails.root.join('tmp', 'csv_header_patterns_summary.txt')
    
    File.open(output_file, 'w') do |file|
      file.puts "CSV Header Patterns Summary"
      file.puts "=========================="
      file.puts "Generated at: #{Time.current}"
      file.puts "Total ETFs analyzed: #{file_counts.keys.count}"
      file.puts "Total files analyzed: #{file_counts.values.sum}"
      file.puts "Unique header patterns found: #{unique_patterns.size}"
      file.puts "\n"
      
      # Sort patterns by frequency (most common first)
      unique_patterns.sort_by { |_, data| -data[:count] }.each_with_index do |(key, pattern), idx|
        file.puts "Pattern #{idx+1}: Found in #{pattern[:count]} files across #{pattern[:tickers].size} ETFs"
        file.puts "  Delimiter: '#{pattern[:delimiter]}'"
        file.puts "  ETFs using this pattern: #{pattern[:tickers].join(', ')}"
        file.puts "  Headers: "
        pattern[:headers].each_with_index do |header, header_idx|
          header_str = header.to_s.strip
          file.puts "    #{header_idx}: '#{header_str}'"
        end
        file.puts "\n"
      end
      
      # Add a special section for ETFs with multiple patterns
      etfs_with_multiple_patterns = file_counts.keys.select do |ticker|
        ticker_patterns = unique_patterns.select { |_, data| data[:tickers].include?(ticker) }
        ticker_patterns.size > 1
      end
      
      if etfs_with_multiple_patterns.any?
        file.puts "\nETFs with multiple header patterns:"
        etfs_with_multiple_patterns.each do |ticker|
          ticker_patterns = unique_patterns.select { |_, data| data[:tickers].include?(ticker) }
          file.puts "  #{ticker}: #{ticker_patterns.size} different patterns"
        end
      end
    end
    
    puts "Summary complete! Report saved to: #{output_file}"
  end
  
  desc "Generate visual HTML comparison of CSV header patterns"
  task visualize_header_patterns: :environment do
    puts "Generating visual CSV header pattern comparison..."
    
    visualizer = EtfData::HeaderPatternVisualizer.new
    if visualizer.analyze
      report_path = visualizer.generate_visual_report
      puts "Visual comparison complete! Report saved to: #{report_path}"
      puts "Open this file in a web browser to view the comparison."
    else
      puts "Analysis failed - no CSV files found"
    end
  end
end 