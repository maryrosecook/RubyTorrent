class Message
  
  MESSAGE_TYPES = { "-1" => :keep_alive,
                     "0" => :choke,
                     "1" => :unchoke,
                     "2" => :interested,
                     "3" => :not_interested,
                     "4" => :have,
                     "5" => :bitfield,
                     "6" => :request,
                     "7" => :piece,
                     "8" => :cancel,
                     "9" => :port }
  
  attr_accessor :peer, :length, :type, :payload
  
  def initialize(peer, length, id, payload)
    @peer = peer
    @length = length
    @type = MESSAGE_TYPES[id.to_s]
    @payload = payload
  end
  
  def self.has_payload?(id)
    # message ids associated with payload
    /[456789]/.match(id)
  end
  
  def print
    "index: #{ self.payload[0..3].unpack("N")}, offset: #{self.payload[4..8].unpack("N") }"
  end
  $count = 0
  def self.parse_stream(peer, message_queue)
    loop do
      begin       
        $count += 1
        length = peer.connection.read(4).unpack("N")[0]
        id = length.zero? ? "-1" : peer.connection.readbyte.to_s
        payload = has_payload?(id) ? peer.connection.read(length - 1) : nil
        message_queue << self.new(peer, length, id, payload)
      rescue => exception
        puts exception
        puts $count
        break
      end
    end
  end
  
  def self.send_interested(peer)
    length = "\0\0\0\1"
    id = "\2"
    peer.connection.write(length + id) 
  end
  
  def self.send_have(peers, index)
    puts "Hey ! #{peers.length}"
    length = "\0\0\0\5"
    id = "\4"
    piece_index = [index].pack("N")
    peers.each do |peer| 
      peer.connection.write(length + id + piece_index)
      puts "sent 'have' message to #{peer.id}"
    end
  
  end
end