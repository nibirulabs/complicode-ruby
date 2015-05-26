require 'complicode/version'
require 'verhoeff'
require 'rc4'
require 'radix'
require 'virtus'

module Complicode
  class Generate
    BASE64 = %w(
      0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V
      W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z + /
    )

    VERIFICATION_DIGITS_LENGTH = 5

    include Virtus.model

    attribute :amount, String
    attribute :authorization_code, String
    attribute :issue_date, String
    attribute :key, String
    attribute :nit_code, String
    attribute :number, String

    attribute :base64_data, String, writer: :private
    attribute :encrypted_data, String, writer: :private
    attribute :verification_digits, String, writer: :private

    def self.call(*args)
      new(*args).call
    end

    def call
      @verification_digits = fetch_verification_digits

      @encrypted_data = encrypt(data_string)

      generate_ascii_sumatories

      @base64_data = fetch_base64_data

      control_code
    end

    private

    def control_code
      encrypt(base64_data).scan(/.{2}/).join('-')
    end

    def data_string
      tmp_key = @key.dup
      partial_strings = string_lenghts.map { |i| tmp_key.slice!(0...i) }

      @authorization_code += partial_strings[0]
      @number += partial_strings[1]
      @nit_code += partial_strings[2]
      @issue_date += partial_strings[3]
      @amount += partial_strings[4]

      [authorization_code, number, nit_code, issue_date, amount].inject(:+)
    end

    def encrypt(data)
      RC4.new(encryption_key).encrypt(data).unpack('H*').first.upcase
    end

    def encryption_key
      @encryption_key ||= key + verification_digits
    end

    def fetch_base64_data
      index = -1
      @ascii_partial_sums.inject(0) do |sum, partial_sum|
        index += 1
        sum + @ascii_total_sum * partial_sum / string_lenghts[index]
      end.b(10).to_s(BASE64)
    end

    def fetch_verification_digits
      2.times do
        @number     = Verhoeff.checksum_of(@number).to_s
        @nit_code   = Verhoeff.checksum_of(@nit_code).to_s
        @issue_date = Verhoeff.checksum_of(@issue_date).to_s
        @amount     = Verhoeff.checksum_of(@amount).to_s
      end

      sum = [number, nit_code, issue_date, amount].map(&:to_i).inject(:+)

      VERIFICATION_DIGITS_LENGTH.times { sum = Verhoeff.checksum_of(sum) }

      sum.to_s[-VERIFICATION_DIGITS_LENGTH..-1]
    end

    def generate_ascii_sumatories
      @ascii_partial_sums = Array.new(VERIFICATION_DIGITS_LENGTH, 0)
      @ascii_total_sum = 0

      encrypted_data.each_byte.with_index do |byte, index|
        @ascii_total_sum += byte
        @ascii_partial_sums[index % VERIFICATION_DIGITS_LENGTH] += byte
      end
    end

    def string_lenghts
      @string_lenghts ||= verification_digits.split('').map { |d| d.to_i + 1 }
    end
  end
end
