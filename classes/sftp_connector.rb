#!/usr/bin/ruby

require 'net/sftp'
require 'uri'

require_relative 'base_connector'


class SFTPConnector < BaseConnector

  # Class initializer.
  #
  # Parameters:
  #   server_config (Hash): configuration with server settings.
  #   logger (Logging object): logging object for messages.
  #
  def initialize server_config, logger
    super server_config, logger
    @private_key = nil
    begin
      @private_key = File.read File.expand_path File.dirname(__FILE__) + '/../' + server_config['ssh_options']['private_key']
    rescue => e
      logger.error 'No private key specified. Using password authentication.'
    end
  end
  
  ##
  # Transfer archive.
  #
  # Parameters:
  #   filename (String): file to be transferred.
  #
  def transfer q, filename
    options = nil
    if @password
      options = { password: @password }
    end
    
    # Override password authentication if private key is provided.
    if @private_key
      options = { 
        key_data: [@private_key],
        auth_methods: ['publickey'],
        keys_only: true,
      }
    end
    
    options.store(:port, @port)
    options.store(:timeout, @timeout)
    options.store(:logger, @logger)
    Net::SFTP.start(@ip, @username, options) do |sftp|
      if !sftp.dir.entries(File.expand_path @dest_folder + '/../').map { |entry| entry.name }.include?(URI(@dest_folder).path.split('/').last)
        @logger.info "Remote directory does not exist: #{@dest_folder}. Creating folder."
        sftp.mkdir(@dest_folder)
      end
      sftp.upload!(filename, @dest_folder)
    end
    q << true
  rescue => e
    @logger.error "Error for #{@name} over #{@type}: #{e.class}."
    q << false
  end
end