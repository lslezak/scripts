# parsing HTML
require "nokogiri"
# URL parsing
require "uri"
# HTTP download
require "net/http"
# HTML -> Markdown conversion
require "kramdown"

# The code is based on the JekyllImport::Importers::RSS code
module JekyllImport
  module Importers
    class LizardRSS < Importer
      def self.specify_options(c)
        c.option 'source', '--source NAME', 'The RSS file or URL to import'
      end

      def self.validate(options)
        if options['source'].nil?
          abort "Missing mandatory option --source."
        end
      end

      def self.require_deps
        JekyllImport.require_with_fallback(%w[
          rss
          rss/1.0
          rss/2.0
          open-uri
          fileutils
          safe_yaml
        ])
      end

      # Process the import.
      #
      # source - a URL or a local file String.
      #
      # Returns nothing.
      def self.process(options)
        source = options.fetch('source')

        content = File.read(source)
        rss = ::RSS::Parser.parse(content, false)

        raise "There doesn't appear to be any RSS items at the source (#{source}) provided." unless rss
        FileUtils.mkdir_p("_posts")

        rss.items.each do |item|
          # convert only the YaST team posts
          import_post(item) if item.dc_creator == "Yast Team"
        end
      end

      def self.import_post(item)
        formatted_date = item.date.strftime('%Y-%m-%d')
        post = item.content_encoded

        # convert MSDOS newlines to Unix newlines
        post.gsub!(/\r\n?/, "\n")
        # emoji conversion
        replace_emoji(post)
        # download images from lizards.opensuse.org and replace the URLs
        download_and_replace_images(post, "images/#{formatted_date}")
        # convert to Markdown
        md_content = Kramdown::Document.new(post, :html_to_native => true).to_kramdown

        file_path = "_posts/#{formatted_date}-#{post_name(item)}.md"
        # add the YAML header
        File.write(file_path, yaml_header(item) + "---\n\n" + md_content)
      end

      # simple&stupid emoji replacement, we used just few emoticons
      # do not overengeneer
      EMOJI = {
        '<img src="https://s.w.org/images/core/emoji/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
        '<img src="https://s.w.org/images/core/emoji/2/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
        '<img src="https://s.w.org/images/core/emoji/72x72/1f642.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:",
        '<img src="https://s.w.org/images/core/emoji/2/72x72/1f642.png" alt="&#x1f642;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:"
      }

      def self.replace_emoji(post)
        EMOJI.each do |link, emoji|
          post.gsub!(link, emoji)
        end
      end

      def self.download_and_replace_images(post, download_dir)
        tree = Nokogiri::HTML(post)

        # replace images
        download_and_replace_tag(tree, download_dir, "img", "src")
        # replace links to images
        download_and_replace_tag(tree, download_dir, "a", "href")

        # build the HTML back from the modified tree, remove the body wrapper
        # added by Nokogiri
        post.replace(tree.xpath("//body").children.to_html)
      end

      def self.download_and_replace_tag(tree, download_dir, tag, attribute)
        # replace only URLs pointing to an uploaded content
        tree.xpath("//#{tag}[contains(@#{attribute},\"//lizards.opensuse.org/wp-content/uploads\")]").each do |node|
          src = node.attribute(attribute).value
          # add HTTPS if there is no protocol
          src = "https:#{src}" if src.start_with?("//")
          url = URI(src)

          if url.scheme == "http" || url.scheme == "https"
            file = File.join(download_dir, File.basename(url.path))
            if !File.exist?(file)
              FileUtils.mkdir_p(download_dir)
              download(url, file)
            end
            # use relative path so it does not depend on the root location
            node.attribute(attribute).value = "../../../../#{file}"
          else
            $stderr.puts "Unknown protocol in URL: #{src}"
          end

          attributes_cleanup(node)
        end
      end

      def self.download(url, file)
        puts "Downloading #{url}..."
        content = Net::HTTP.get(url)

        puts "Saving to #{file}"
        File.write(file, content)
      end

      def self.yaml_header(item)
        header = {
          'layout' => 'post',
          'date' => item.pubDate,
          'title' => item.title,
          'description' => item.description,
          # the catogires and tags must be fixed manually
          # RSS feed mixes both into a single list
          'category' => item.categories.map(&:content),
          'tags' => item.categories.map(&:content),
        }

        header.to_yaml
      end

      def self.post_name(item)
        name = item.title.split(%r{ |!|’|/|:|&|-|$|,|\(|\)}).map do |i|
          i.downcase if i != ''
        end

        name.compact.join('-')
      end

      # delete unused attributes
      def self.attributes_cleanup(node)
        node.delete("width")
        node.delete("height")
        node.delete("class")
        node.delete("srcset")
        node.delete("sizes")
      end
    end
  end
end
