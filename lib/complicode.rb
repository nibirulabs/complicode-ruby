require 'complicode/version'

require 'radix'
require 'rc4'
require 'verhoeff'

module Complicode
  class Generate
    BASE64 = %w(
      0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V
      W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z + /
    ).freeze

    VERIFICATION_DIGITS_LENGTH = 5

    def self.call(*args)
      new(*args).send(:call)
    end

    private

    def initialize(authorization_code:, key:, amount:, issue_date:, invoice_number:, nit: 0)
      @authorization_code = authorization_code.to_s
      @key = key.to_s
      @nit = nit.to_s
      @amount = amount.to_d.round.to_s
      @issue_date = issue_date.to_s
      @invoice_number = invoice_number.to_s
    end

    def call
      encryption_key = generate_encryption_key
      encrypted_data = encrypt(data_string, encryption_key)
      ascii_sums     = generate_ascii_sums(encrypted_data)
      base64_data    = generate_base64_data(ascii_sums)
      code           = encrypt(base64_data, encryption_key)
      format(code)
    end

    def generate_encryption_key
      @key + verification_digits
    end

    def verification_digits
      @verification_digits ||= generate_verification_digits
    end

    def generate_verification_digits
      2.times do
        @invoice_number += Verhoeff.checksum_digit_of(@invoice_number).to_s
        @nit            += Verhoeff.checksum_digit_of(@nit).to_s
        @issue_date     += Verhoeff.checksum_digit_of(@issue_date).to_s
        @amount         += Verhoeff.checksum_digit_of(@amount).to_s
      end

      sum = [@invoice_number, @nit, @issue_date, @amount].map(&:to_i).inject(:+)

      VERIFICATION_DIGITS_LENGTH.times { sum = Verhoeff.checksum_of(sum) }

      sum.to_s[-VERIFICATION_DIGITS_LENGTH..-1]
    end

    def data_string
      tmp_key = @key.dup
      partial_strings = string_lengths.map { |i| tmp_key.slice!(0...i) }

      @authorization_code += partial_strings[0]
      @invoice_number += partial_strings[1]
      @nit += partial_strings[2]
      @issue_date += partial_strings[3]
      @amount += partial_strings[4]

      [@authorization_code, @invoice_number, @nit, @issue_date, @amount].inject(:+)
    end

    def encrypt(data, encryption_key)
      RC4.new(encryption_key).encrypt(data).unpack('H*').first.upcase
    end

    def generate_base64_data(ascii_sums)
      ascii_sums.partials.each_with_index.inject(0) do |sum, (partial_sum, index)|
        sum + ascii_sums.total * partial_sum / string_lengths[index]
      end.b(10).to_s(BASE64)
    end

    AsciiSums = Struct.new(:total, :partials)

    def generate_ascii_sums(encrypted_data)
      AsciiSums.new(0, Array.new(VERIFICATION_DIGITS_LENGTH, 0)).tap do |sums|
        encrypted_data.each_byte.with_index do |byte, index|
          sums.total += byte
          sums.partials[index % VERIFICATION_DIGITS_LENGTH] += byte
        end
      end
    end

    def string_lengths
      @string_lengths ||= verification_digits.split('').map { |d| d.to_i + 1 }
    end

    def format(code)
      code.scan(/.{2}/).join('-')
    end
  end
end
