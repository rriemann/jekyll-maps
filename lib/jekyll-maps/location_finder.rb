module Jekyll
  module Maps
    class LocationFinder
      def initialize(options)
        @documents = []
        @options = options
      end

      def find(site, page)
        if @options[:filters].empty?
          @documents << page if with_location?(page)
        else
          site.collections.each { |_, collection| filter(collection.docs) }
          site_data(site).each { |_, items| traverse(items) }
        end

        documents_to_locations
      end

      private
      def site_data(site)
        return {} unless data_source?

        path = @options[:filters]["src"].scan(%r!_data\/([^\/]+)!).join(".")
        return site.data if path.empty?

        data = OpenStruct.new(site.data)
        if @options[:filters]["src"] =~ %r!\.ya?ml!
          { :path => data[path.gsub(%r!\.ya?ml!, "")] }
        else
          data[path]
        end
      end

      private
      def data_source?
        filters = @options[:filters]
        filters.key?("src") && filters["src"].start_with?("_data")
      end

      private
      def traverse(items)
        return filter(items) if items.is_a?(Array)

        items.each { |_, children| traverse(children) } if items.is_a?(Hash)
      end

      private
      def filter(docs)
        docs.each do |doc|
          @documents << doc if with_location?(doc) && match_filters?(doc)
        end
      end

      private
      def with_location?(doc)
        !doc["location"].nil? && !doc["location"].empty?
      end

      private
      def match_filters?(doc)
        @options[:filters].each do |filter, value|
          if filter == "src"
            return true unless doc.respond_to?(:relative_path)
            return false unless doc.relative_path.start_with?(value)
          elsif doc[filter].nil? || doc[filter] != value
            return false
          end
        end
      end

      private
      def documents_to_locations
        locations = []
        @documents.each do |document|
          if document["location"].is_a?(Array)
            document["location"].each do |location|
              locations.push(convert(document, location))
            end
          else
            locations.push(convert(document, document["location"]))
          end
        end
        locations
      end

      private
      def convert(document, location)
        {
          :latitude  => location["latitude"],
          :longitude => location["longitude"],
          :title     => location["title"] || document["title"],
          :url       => location["url"] || fetch_url(document),
          :image     => location["image"] || document["image"] || ""
        }
      end

      private
      def fetch_url(document)
        return document["url"] if document.is_a?(Hash) && document.key?("url")
        return document.url if document.respond_to? :url
        ""
      end
    end
  end
end
