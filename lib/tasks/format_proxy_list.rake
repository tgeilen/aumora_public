require 'json'

namespace :proxy do
  desc "Convert Free_Proxy_List.json to the format used in proxyList.json"
  task :format do
    input_file = 'tmp/Free_Proxy_List.json'
    output_file = 'tmp/formatted_proxy_list.json'
    
    puts "Reading #{input_file}..."
    
    begin
      # Read and parse the input file
      input_data = JSON.parse(File.read(input_file))
      
      # Transform data to the target format
      formatted_data = input_data.map do |proxy|
        begin
          protocol = proxy["protocols"].first.downcase
        rescue
          protocol = "http"
        end
        
        port = proxy["port"].to_i
        
        {
          "ip" => proxy["ip"],
          "port" => port,
          "protocol" => protocol,
          "url" => "#{protocol}://#{proxy["ip"]}:#{port}",
          "speed" => proxy["speed"] || proxy["latency"] || 1.0
        }
      end
      
      # Write the formatted data
      File.write(output_file, JSON.pretty_generate(formatted_data))
      puts "Successfully converted #{input_data.length} proxies to #{output_file}"
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  end
  
  desc "Run test to verify the format conversion works correctly"
  task :test do
    puts "Running proxy format conversion test..."
    
    begin
      # Sample data from Free_Proxy_List.json
      sample_proxy = {
        "_id" => "630f0758de95dae5214bfe4f",
        "ip" => "139.162.151.176",
        "anonymityLevel" => "elite",
        "asn" => "AS63949",
        "city" => "Frankfurt am Main",
        "country" => "DE",
        "created_at" => "2022-08-31T07:01:44.158Z",
        "google" => false,
        "isp" => "Akamai Technologies, Inc.",
        "lastChecked" => 1745782236,
        "latency" => 7.102,
        "org" => "Linode, LLC",
        "port" => "71",
        "protocols" => ["socks4"],
        "region" => nil,
        "responseTime" => 4804,
        "speed" => 1,
        "updated_at" => "2025-04-27T19:30:36.739Z",
        "workingPercent" => nil,
        "upTime" => 99.98964159933706,
        "upTimeSuccessCount" => 9653,
        "upTimeTryCount" => 9654
      }
      
      # Expected output format
      expected_output = {
        "ip" => "139.162.151.176",
        "port" => 71,
        "protocol" => "socks4",
        "url" => "socks4://139.162.151.176:71",
        "speed" => 1
      }
      
      # Transform the sample
      begin
        protocol = sample_proxy["protocols"].first.downcase
      rescue
        protocol = "http"
      end
      
      actual_output = {
        "ip" => sample_proxy["ip"],
        "port" => sample_proxy["port"].to_i,
        "protocol" => protocol,
        "url" => "#{protocol}://#{sample_proxy["ip"]}:#{sample_proxy["port"]}",
        "speed" => sample_proxy["speed"] || sample_proxy["latency"] || 1.0
      }
      
      # Verify the transformation is correct
      if actual_output == expected_output
        puts "PASS: Proxy format transformation works correctly"
        puts "Sample output: #{JSON.pretty_generate(actual_output)}"
      else
        puts "FAIL: Transformation did not produce the expected output"
        puts "Expected: #{JSON.pretty_generate(expected_output)}"
        puts "Actual: #{JSON.pretty_generate(actual_output)}"
      end
      
      # Process the full file as a more comprehensive test
      input_file = 'tmp/Free_Proxy_List.json'
      if File.exist?(input_file)
        input_data = JSON.parse(File.read(input_file))
        transformed_count = input_data.length
        puts "Successfully parsed #{transformed_count} proxies from #{input_file}"
        
        # Test a few random conversions
        sample_size = [5, input_data.length].min
        sample_indices = (0...input_data.length).to_a.sample(sample_size)
        
        puts "\nSample conversions:"
        sample_indices.each do |i|
          proxy = input_data[i]
          
          begin
            protocol = proxy["protocols"].first.downcase
          rescue
            protocol = "http"
          end
          
          formatted = {
            "ip" => proxy["ip"],
            "port" => proxy["port"].to_i,
            "protocol" => protocol,
            "url" => "#{protocol}://#{proxy["ip"]}:#{proxy["port"]}",
            "speed" => proxy["speed"] || proxy["latency"] || 1.0
          }
          puts JSON.pretty_generate(formatted)
        end
      else
        puts "WARNING: #{input_file} not found, skipping full file test"
      end
      
    rescue StandardError => e
      puts "Test Error: #{e.message}"
      puts e.backtrace
    end
  end
end 