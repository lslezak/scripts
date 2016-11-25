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
          next unless item.dc_creator == "Yast Team"

          formatted_date = item.date.strftime('%Y-%m-%d')
          post_name = item.title.split(%r{ |!|/|:|&|-|$|,|\(|\)}).map do |i|
            i.downcase if i != ''
          end.compact.join('-')
          name = "#{formatted_date}-#{post_name}"

          header = {
            'layout' => 'post',
            'title' => item.title,
            'description' => item.description,
            'category' => 'YaST',
            'tags' => 'Report'
            # TODO: include the publishing date
          }

          html_path = "_posts/#{name}.html"
          md_path = "_posts/#{name}.md"
          
          post = item.content_encoded

          # emoji conversion
          replace_emoji(post)
          
          # TODO: download images
          File.write(html_path, post)

          # convert HTML to Markdown
          `html2text-python2.7 #{html_path} > #{md_path}`

          # add the YAML header
          md_content = File.read(md_path)
          File.write(md_path, header.to_yaml + "---\n\n" + md_content)

        end
      end

      # simple stupid emoji replacement
      EMOJI = {
        '<img src="https://s.w.org/images/core/emoji/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
        '<img src="https://s.w.org/images/core/emoji/2/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
        '<img src="https://s.w.org/images/core/emoji/72x72/1f642.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:",
        '<img src="https://s.w.org/images/core/emoji/2/72x72/1f642.png" alt="&#x1f642;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:"
      }

      def self.replace_emoji(post)
        EMOJI.each do |link, emoji|
          puts "Found #{emoji}" if post.include?(link)
          post.gsub!(link, emoji)
        end
      end
    end
  end
end
