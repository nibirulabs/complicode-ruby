require 'complicode/version'

require 'radix'
require 'rc4'
require 'verhoeff'
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
    attribute :nit, String, default: 0, required: false
    attribute :invoice_number, String

    def self.call(*args)
      new(*args).call
    end

    def self.required_attrs
      attribute_set.select(&:required?).map(&:name)
    end

    def initialize(*args)
      super
      validate_attributes
    end

    def call
      @verification_digits = fetch_verification_digits

      @encrypted_data = encrypt(data_string)

      generate_ascii_sums

      @base64_data = fetch_base64_data

      control_code
    end

    private

    def control_code
      encrypt(@base64_data).scan(/.{2}/).join('-')
    end

    def data_string
      tmp_key = @key.dup
      partial_strings = string_lengths.map { |i| tmp_key.slice!(0...i) }

      @authorization_code += partial_strings[0]
      @invoice_number += partial_strings[1]
      @nit += partial_strings[2]
      @issue_date += partial_strings[3]
      @amount += partial_strings[4]

      [authorization_code, invoice_number, nit, issue_date, amount].inject(:+)
    end

    def encrypt(data)
      RC4.new(encryption_key).encrypt(data).unpack('H*').first.upcase
    end

    def encryption_key
      @encryption_key ||= key + @verification_digits
    end

    def fetch_base64_data
      index = -1
      @ascii_partial_sums.inject(0) do |sum, partial_sum|
        index += 1
        sum + @ascii_total_sum * partial_sum / string_lengths[index]
      end.b(10).to_s(BASE64)
    end

    def fetch_verification_digits
      2.times do
        @invoice_number += Verhoeff.checksum_digit_of(@invoice_number).to_s
        @nit            += Verhoeff.checksum_digit_of(@nit).to_s
        @issue_date     += Verhoeff.checksum_digit_of(@issue_date).to_s
        @amount         += Verhoeff.checksum_digit_of(@amount).to_s
      end

      sum = [invoice_number, nit, issue_date, amount].map(&:to_i).inject(:+)

      VERIFICATION_DIGITS_LENGTH.times { sum = Verhoeff.checksum_of(sum) }

      sum.to_s[-VERIFICATION_DIGITS_LENGTH..-1]
    end

    def generate_ascii_sums
      @ascii_partial_sums = Array.new(VERIFICATION_DIGITS_LENGTH, 0)
      @ascii_total_sum = 0

      @encrypted_data.each_byte.with_index do |byte, index|
        @ascii_total_sum += byte
        @ascii_partial_sums[index % VERIFICATION_DIGITS_LENGTH] += byte
      end
    end

    def missing_attrs
      @missing_attrs ||= Generate.required_attrs - valid_attribute_names
    end

    def missing_attrs_error
      "Missing attributes: #{missing_attrs.join(',')}"
    end

    def string_lengths
      @string_lengths ||= @verification_digits.split('').map { |d| d.to_i + 1 }
    end

    def validate_attributes
      raise ArgumentError, missing_attrs_error unless missing_attrs.empty?
    end

    def valid_attribute_names
      @valid_attribute_names ||= attributes.reject { |_, v| v.nil? }.keys
    end
  end
end
