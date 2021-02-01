#!/usr/bin/ruby

require 'net/scp'

require_relative 'base_connector'


class SCPConnector < BaseConnector

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
  #   q         (Queue):   out queue for transfer results.
  #   filename  (String):  file to be transferred.
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
        keys_only: true
      }
    end
    
    options.store(:port, @port)
    options.store(:timeout, @timeout)
    options.store(:logger, @logger)
    Net::SSH.start(@ip, @username, options) do |ssh|
      ssh.scp.upload!(filename, @dest_folder)
    end
    q << true
  rescue => e
    @logger.error "Error for #{@name} over #{@type}: #{e.class}"
    q << false
  end
end