require 'nokogiri'
require "ember_cli/assets/errors"

module EmberCli
  module Assets
    class AssetMap
      def initialize(name:, asset_map:, index_html:)
        @name = name
        @asset_map = asset_map
        @index_html = index_html
      end

      def javascripts
        assert_asset_map!

        Nokogiri::HTML(index_html.read).css('script').map {|s|
          filename = File.basename(s['src'])
          asset_matching(/#{Regexp.escape(filename)}\z/)
        }
      end

      def stylesheets
        assert_asset_map!

        Nokogiri::HTML(index_html.read).css('link[rel="stylesheet"]').map {|s|
          href = s['href']
          if href =~ /^http/
            href
          else
            filename = File.basename(s['href'])
            asset_matching(/#{Regexp.escape(filename)}\z/)
          end
        }
      end

      private

      attr_reader :name, :asset_map, :index_html

      def asset_matching(regex)
        matching_asset = files.detect { |asset| asset =~ regex }

        if matching_asset.to_s.empty?
          raise_missing_asset(regex)
        end

        prepend + matching_asset
      end

      def prepend
        asset_map["prepend"].to_s
      end

      def files
        Array(assets.values)
      end

      def assets
        asset_map["assets"] || {}
      end

      def raise_missing_asset(regex)
        raise BuildError.new("Failed to find assets matching `#{regex}`")
      end

      def assert_asset_map!
        if assets.empty?
          raise BuildError.new <<-MSG
            Missing `#{name}/assets/assetMap.json`
          MSG
        end
      end
    end
  end
end
