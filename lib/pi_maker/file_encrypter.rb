require 'openssl'

module PiMaker
  # Encrypt and decrypt files using openssl
  module FileEncrypter
    class << self
      # Regex for files encrypted with this method
      ENCRYPTED_FILE_MATCHER = /^.{16}\nJ\nT\nP/.freeze

      # Given +opts+ for the :data to encrypt, and a :password to encrypt it with, returns an
      # encoded string
      def encrypt(str, passwd)
        new_cipher.encrypt

        cipher.key = key_from_password(passwd)
        vector = cipher.random_iv

        data = cipher.update(str) + cipher.final

        [vector, "\nJ\nT\nP", data].join
      end

      # Given +opts+ for the :data to decrypt, and a :password to decrypt it with, returns the
      # original string
      def decrypt(str, passwd)
        vector, data = str.split("\nJ\nT\nP")

        new_cipher.decrypt

        cipher.iv = vector
        cipher.key = key_from_password(passwd)

        cipher.update(data) + cipher.final
      end

      # Given a +str+ and a +passwd+, decides whether to encrypt or decrypt based on matching the
      # ENCRYPTED_FILE_MATCHER and then does so
      def call(str, passwd)
        str.match?(ENCRYPTED_FILE_MATCHER) ? decrypt(str, passwd) : encrypt(str, passwd)
      end

      alias [] call

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
