require 'testing_env'

require 'extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
ARGV.extend(HomebrewArgvExtension)

require 'base32'


class Base32Tests < Test::Unit::TestCase

  BASE16 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
  BASE32 = 'SEOC8GKOVGE196NRUJ49IRTP4GJQSGF4CIDP6J54IMCHMU2IN1AG===='

  def test_encode32hex
    binary = BASE16.gsub(/../) { |match| match.hex.chr }
    assert Base32.encode32hex(binary) == BASE32
  end

  def test_decode32hex
    binary = BASE16.gsub(/../) { |match| match.hex.chr }
    assert Base32.decode32hex(BASE32) == binary
  end

end
