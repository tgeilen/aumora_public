module EtfData
  module Fetchers
    class BaseFetcher
      attr_reader :provider, :logger

      def initialize(provider)
        @provider = provider
        @logger = Rails.logger
      end

      # Abstract method to fetch ETF list
      def fetch_etf_list
        raise NotImplementedError, "#{self.class} must implement #fetch_etf_list"
      end

      # Abstract method to fetch ETF holdings
      def fetch_etf_holdings(etf)
        raise NotImplementedError, "#{self.class} must implement #fetch_etf_holdings"
      end

      # Abstract method to find ETF URL from JustETF
      def find_etf_url(etf)
        raise NotImplementedError, "#{self.class} must implement #find_etf_url"
      end

      protected

      def download_file(url, output_path)
        logger.info("Downloading file from #{url} to #{output_path}")
        
        begin
          # Set timeout options
          options = {
            timeout: 30, # 30 seconds timeout for the request
            open_timeout: 10 # 10 seconds timeout for opening connection
          }
          
          response = HTTParty.get(url, options)
          
          if response.success?
            logger.debug("Download successful: HTTP #{response.code}, Content length: #{response.body.length} bytes")
            
            # Check if the content seems valid
            if response.body.nil? || response.body.empty?
              logger.error("Download from #{url} returned empty content")
              return false
            end
            
            # Log content type and size
            content_type = response.headers['content-type']
            content_length = response.headers['content-length']
            logger.debug("Content-Type: #{content_type}, Content-Length: #{content_length}")
            
            # Save the file
            File.open(output_path, 'wb') do |file|
              file.write(response.body)
            end
            
            # Verify file was created and has content
            if File.exist?(output_path) && File.size(output_path) > 0
              logger.info("File saved successfully to #{output_path} (#{File.size(output_path)} bytes)")
              true
            else
              logger.error("File save failed or file is empty: #{output_path}")
              false
            end
          else
            # Detailed error logging for failed requests
            logger.error("Failed to download file from #{url}: HTTP #{response.code} - #{response.message}")
            
            # Log response headers for debugging
            logger.debug("Response headers: #{response.headers}")
            
            # Log a sample of the response body if available
            if response.body.present?
              body_sample = response.body.slice(0, 300) + "..."
              logger.debug("Response body sample: #{body_sample}")
            end
            
            # Handle specific HTTP status codes
            case response.code
            when 404
              logger.error("File not found (404): The requested URL does not exist")
            when 403
              logger.error("Access forbidden (403): The server refused access to the requested URL")
            when 401
              logger.error("Unauthorized (401): Authentication required for the requested URL")
            when 429
              logger.error("Rate limit exceeded (429): The server is rate limiting requests")
            when 500..599
              logger.error("Server error (#{response.code}): The server encountered an error")
            end
            
            false
          end
        rescue Net::OpenTimeout => e
          logger.error("Timeout opening connection to #{url}: #{e.message}")
          false
        rescue Net::ReadTimeout => e
          logger.error("Timeout reading data from #{url}: #{e.message}")
          false
        rescue SocketError => e
          logger.error("Socket error for #{url}: #{e.message}")
          false
        rescue => e
          logger.error("Error downloading file from #{url}: #{e.class.name} - #{e.message}")
          logger.error(e.backtrace.join("\n"))
          false
        end
      end

      def create_temp_directory
        dir = Rails.root.join('tmp', 'etf_data', provider.name.parameterize)
        FileUtils.mkdir_p(dir)
        dir
      end
    end
  end
end 