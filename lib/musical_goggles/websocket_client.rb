# frozen_string_literal: true

require 'websocket'
require 'uri'

module MusicalGoggles
  class WebsocketClient

    UnfinisheHandshake = Class.new(StandardError)
    InvalidHandshake = Class.new(StandardError)

    attr_reader :uri, :handshake, :version, :logger

    def initialize(url:, logger:)
      @handshake = WebSocket::Handshake::Client.new(url: url)
      @version = handshake.version
      @logger = logger
      @uri = URI(url)
    end

    def socket
      @socket ||= TCPSocket.new(uri.host, uri.port)
    end

    def connect
      socket.print(handshake.to_s)
      receive_hanshake
    end

    def close
      send("Bye", type: :close)
      socket.close
    end

    def receive_hanshake
      response = ''
      line = nil
      wait_for_read
      while line != "\r\n"
        line = socket.gets
        response += line
      end
      handshake << response
      raise UnfinisheHandshake unless handshake.finished?
      raise InvalidHandshake unless handshake.valid?
    end

    def receive(timeout = 1)
      frame = WebSocket::Frame::Incoming::Client.new(version: version)
      wait_for_read(timeout)
      frame << socket.read_nonblock(4096)
      result = frame.next
      if result.type == :text
        logger.debug "text frame received: [#{result}]"
        result.to_s
      else
        logger.debug "non-text ws frame received: [#{result.type}]"
        receive(timeout)
      end
    rescue IO::WaitReadable
      retry
    end

    def send(data, type: :text)
      frame = WebSocket::Frame::Outgoing::Client.new(
        version: version,
        data: data,
        type: type
      )
      wait_for_write
      socket.print frame.to_s
    end

    def wait_for_read(timeout = 1)
      select([socket], [], [], timeout)
    end

    def wait_for_write
      select([], [socket], [], 1)
    end
  end
end
