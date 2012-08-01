module Base32
  TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

  class Chunk
    def initialize(bytes)
      @bytes = bytes
    end

    def decode
      bytes = @bytes.take_while {|c| c != 61} # strip padding
      n = (bytes.length * 5.0 / 8.0).floor
      p = bytes.length < 8 ? 5 - (n * 8) % 5 : 0
      c = bytes.inject(0) {|m,o| (m << 5) + TABLE.index(o.chr)} >> p
      (0..n-1).to_a.reverse.collect {|i| ((c >> i * 8) & 0xff).chr}
    end

    def encode
      n = (@bytes.length * 8.0 / 5.0).ceil
      p = n < 8 ? 5 - (@bytes.length * 8) % 5 : 0
      c = @bytes.inject(0) {|m,o| (m << 8) + o} << p
      [(0..n-1).to_a.reverse.collect {|i| TABLE[(c >> i * 5) & 0x1f].chr},
       ("=" * (8-n))]
    end
  end

  def self.chunks(str, size)
    result = []
    bytes = str.bytes
    while bytes.any? do
      result << Chunk.new(bytes.take(size))
      bytes = bytes.drop(size)
    end
    result
  end

  def self.encode(str)
    chunks(str, 5).collect(&:encode).flatten.join
  end

  def self.decode(str)
    chunks(str, 8).collect(&:decode).flatten.join
  end
end
