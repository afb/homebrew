require 'testing_env'

require 'extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
ARGV.extend(HomebrewArgvExtension)

require 'base32'


class Base32Tests < Test::Unit::TestCase

  BASE16 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
  BASE32 = '4OYMIQUY7QOBJGX36TEJS35ZEQT24QPEMSNZGTFESWMRW6CSXBKQ===='

  def test_encode32
    binary = BASE16.gsub(/../) { |match| match.hex.chr }
    assert Base32.encode(binary) == BASE32
  end

  def test_decode32
    binary = BASE16.gsub(/../) { |match| match.hex.chr }
    assert Base32.decode(BASE32) == binary
  end

end
