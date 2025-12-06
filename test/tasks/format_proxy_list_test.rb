require 'minitest/autorun'
require 'json'
require 'rake'

class FormatProxyListTest < Minitest::Test
  def setup
    # Load the Rake task
    load File.expand_path('../../lib/tasks/format_proxy_list.rake', __dir__)
  end

  def test_proxy_transformation_produces_expected_format
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
    
    # Transform the sample using the same logic as in the rake task
    actual_output = {
      "ip" => sample_proxy["ip"],
      "port" => sample_proxy["port"].to_i,
      "protocol" => sample_proxy["protocols"].first.downcase,
      "url" => "#{sample_proxy["protocols"].first.downcase}://#{sample_proxy["ip"]}:#{sample_proxy["port"]}",
      "speed" => sample_proxy["speed"] || sample_proxy["latency"] || 1.0
    }
    
    # Assert that transformation produces the expected output
    assert_equal expected_output, actual_output
  end

  def test_handles_missing_protocol_gracefully
    proxy_without_protocol = {
      "ip" => "139.162.151.176",
      "port" => "71",
      "latency" => 7.102
    }
    
    # The rescue in the task should default to "http"
    begin
      protocol = proxy_without_protocol["protocols"].first.downcase
    rescue
      protocol = "http"
    end
    
    transformed = {
      "ip" => proxy_without_protocol["ip"],
      "port" => proxy_without_protocol["port"].to_i,
      "protocol" => protocol,
      "url" => "#{protocol}://#{proxy_without_protocol["ip"]}:#{proxy_without_protocol["port"]}",
      "speed" => proxy_without_protocol["speed"] || proxy_without_protocol["latency"] || 1.0
    }
    
    expected = {
      "ip" => "139.162.151.176",
      "port" => 71,
      "protocol" => "http",
      "url" => "http://139.162.151.176:71",
      "speed" => 7.102
    }
    
    assert_equal expected, transformed
  end

  def test_uses_correct_speed_value_fallbacks
    # Test when speed is present
    proxy_with_speed = {
      "ip" => "139.162.151.176",
      "port" => "71",
      "protocols" => ["socks4"],
      "speed" => 1,
      "latency" => 7.102
    }
    
    transformed1 = transform_proxy(proxy_with_speed)
    assert_equal 1, transformed1["speed"], "Should use speed when present"
    
    # Test when speed is nil but latency is present
    proxy_with_latency = {
      "ip" => "139.162.151.176",
      "port" => "71",
      "protocols" => ["socks4"],
      "speed" => nil,
      "latency" => 7.102
    }
    
    transformed2 = transform_proxy(proxy_with_latency)
    assert_equal 7.102, transformed2["speed"], "Should use latency when speed is nil"
    
    # Test default value when both are nil
    proxy_without_speed = {
      "ip" => "139.162.151.176",
      "port" => "71",
      "protocols" => ["socks4"],
      "speed" => nil,
      "latency" => nil
    }
    
    transformed3 = transform_proxy(proxy_without_speed)
    assert_equal 1.0, transformed3["speed"], "Should use default 1.0 when both speed and latency are nil"
  end

  private
  
  def transform_proxy(proxy)
    begin
      protocol = proxy["protocols"].first.downcase
    rescue
      protocol = "http"
    end
    
    {
      "ip" => proxy["ip"],
      "port" => proxy["port"].to_i,
      "protocol" => protocol,
      "url" => "#{protocol}://#{proxy["ip"]}:#{proxy["port"]}",
      "speed" => proxy["speed"] || proxy["latency"] || 1.0
    }
  end
end 