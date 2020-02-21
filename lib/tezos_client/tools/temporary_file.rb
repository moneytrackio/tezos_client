# frozen_string_literal: true

class TezosClient
  module Tools
    module TemporaryFile
      def self.with_file_copy(source_file_path)
        source_file = File.open(source_file_path, "r")
        source_extention = File.extname(source_file_path)

        file_copy_path = nil

        res = Tools::TemporaryFile.with_tempfile(source_extention) do |file_copy|
          file_copy.write(source_file.read)
          file_copy_path = file_copy.path
          file_copy.close
          yield(file_copy_path)
        end

        res
      ensure
        File.delete(file_copy_path) if File.exist? file_copy_path
      end

      def self.with_tempfile(extension)
        file = Tempfile.new(["script", extension])
        yield(file)
      ensure
        file.unlink
      end
    end
  end
end
