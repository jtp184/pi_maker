require 'openssl'

module PiMaker
  # Encrypt and decrypt files using openssl
  module FileEncrypter
    # Regex for files encrypted with this method
    HEADER = "J\nT\nP\n".freeze

    class << self
      # Given the +str+ to encrypt, and an optional passwd to encrypt it with, returns an
      # encoded string, or the string itself if no password is given
      def encrypt(str, passwd = nil)
        return str if passwd.nil?

        new_cipher.encrypt

        cipher.key = key_from_password(passwd)
        vector = cipher.random_iv

        data = cipher.update(str) + cipher.final

        [HEADER, vector, data].join
      end

      # Given the +str to decrypt, and a +passwd+ to decrypt it with, returns the
      # original string. Raises a PasskeyError if a passwd is not provided, or the string
      # if it doesn't need to be
      def decrypt(str, passwd = nil)
        return str unless encrypted?(str)
        raise PasskeyError, 'No password provided' if passwd.nil?

        vector = str[HEADER.length...(HEADER.length + 16)]
        data = str[(16 + HEADER.length)..-1]

        new_cipher.decrypt

        cipher.iv = vector
        cipher.key = key_from_password(passwd)

        cipher.update(data) + cipher.final
      end

      # Given a +str+ and a +passwd+, decides whether to encrypt or decrypt based on utf8
      def call(str, passwd)
        encrypted?(str) ? decrypt(str, passwd) : encrypt(str, passwd)
      end

      alias [] call

      # Returns true for strings that have the HEADER in the right location
      def encrypted?(str)
        str[0...HEADER.length] == HEADER
      end

      private

      # Reader for the cipher class
      attr_reader :cipher

      # Given the +passwd+, converts it into a 16 byte key using OpenSSL::KDF.pbkdf2_hmac
      def key_from_password(passwd)
        OpenSSL::KDF.pbkdf2_hmac(
          passwd,
          iterations: 16,
          length: 16,
          hash: 'sha256',
          salt: 'JTP184 / PIMAKER'
        )
      end

      # Set the instanced cipher to a new instance
      def new_cipher
        @cipher = OpenSSL::Cipher.new('AES-128-CBC')
      end
    end
  end
end
