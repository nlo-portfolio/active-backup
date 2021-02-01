#!/usr/bin/ruby

require 'net/ftp'

require_relative 'base_connector'


class FTPConnector < BaseConnector

  # Class initializer.
  #
  # Parameters:
  #   server_config (Hash): configuration with server settings.
  #   logger (Logging object): logging object for messages.
  #
  def initialize server_config, logger
    super server_config, logger
    @password = server_config['password']
    @passive = server_config['ftp_options']['passive']
  end
  
  ##
  # Transfer archive.
  #
  # Parameters:
  #   filename (String): file to be transferred.
  #
  def transfer q, filename
    options = {
      port: @port,
      username: @username,
      password: @password,
      passive: @passive,
      timeout: @timeout,
      logger: @logger
    }

    Net::FTP.open(@ip, options) do |ftp|
      ftp.putbinaryfile(filename, @dest_folder)
    end
    q << true
  rescue => e
    @logger.error "Error for #{@name} over #{@type}: #{e.class}."
    q << false
  end
end
