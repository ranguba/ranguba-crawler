# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "cgi/util"
require "find"
require "json"
require "net/http"
require "optparse"
require "pathname"
require "pp"
require "uri"

module RangubaCrawler
  class Command
    def initialize(argv)
      @argv = argv
      @server_url = "http://localhost:3000/"
      @suffix = nil
    end

    def run
      return false unless parse_argv

      api_uri = URI(@server_url) + "/scraping.json"
      @targets.each do |base_path|
        Find.find(base_path) do |path|
          path = Pathname(path)
          next if path.directory?
          if @suffix
            next unless path.extname == @suffix
          end
          parameters = {
            "uri" => path_to_uri(path),
            "body" => path.open("rb", &:read),
          }
          response = Net::HTTP.post_form(api_uri, parameters)
          case response
          when Net::HTTPSuccess
            # pp(JSON.parse(response.body))
          else
            puts("Failed to request: #{response.code}")
            puts(path)
            # puts(api_uri)
            # pp(parameters.inspect)
            # puts(response.body)
          end
        end
      end

      true
    end

    private
    def create_option_parser
      parser = OptionParser.new
      parser.banner += " PATH PATH ..."
      parser.version = RangubaCrawler::VERSION

      parser.on("--server-url=URL",
                "Ranguba server URL",
                "(#{@server_url})") do |url|
        @server_url = url
      end

      parser.on("--suffix=SUFFIX",
                "Target suffix",
                "(all)") do |suffix|
        @suffix = suffix
      end

      parser
    end

    def parse_argv
      parser = create_option_parser
      @targets = parser.parse(@argv)
      true
    end

    def path_to_uri(path)
      components = path.expand_path.to_s.split(Pathname::SEPARATOR_PAT)
      escaped_components = components.collect do |component|
        CGI.escape(component)
      end
      "file://" + File.join(*escaped_components)
    end
  end
end
