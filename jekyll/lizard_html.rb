# parsing HTML
require "nokogiri"
# URL parsing
require "uri"
# HTTP download
require "net/http"
# HTML -> Markdown conversion
require "kramdown"
# parse date
require "date"

class LizardHtmlImporter
  attr_reader :html_file

  def initialize(html_file)
    @html_file = html_file
  end

  # import only some posts, the rest is imported via the RSS feed
  POSTS_TO_IMPORT = [
    "Highlights of YaST development sprint 21",
    "Highlights of YaST development sprint 22",
    "Highlights of YaST development sprint 23"
  ]

  # Process the import.
  def process
    tree = Nokogiri::HTML(File.read(html_file))

    FileUtils.mkdir_p("_posts")

    # find all posts
    tree.xpath("//div[contains(@class,\"post\")]").each do |post|
      # import only the listed posts
      import_post(post) if POSTS_TO_IMPORT.include?(post_title(post))
    end
  end

  def import_post(post)
    puts "Importing post \"#{post_title(post)}\"..."
    content = post.xpath("div[@class=\"entry\"]").first
    formatted_date = post_date(post).strftime('%Y-%m-%d')

    # download images from lizards.opensuse.org and replace the URLs
    download_and_replace_images(content, "images/#{formatted_date}")

    html = content.children.to_html

    # convert MSDOS newlines to Unix newlines
    html.gsub!(/\r\n?/, "\n")

    # emoji conversion
    replace_emoji(html)

    # convert to Markdown
    md_content = Kramdown::Document.new(html, :html_to_native => true).to_kramdown

    file_path = "_posts/#{formatted_date}-#{post_file_name(post)}.md"
    # add the YAML header
    File.write(file_path, yaml_header(post) + "---\n\n" + md_content)
  end

  # simple&stupid emoji replacement, we used just few emoticons
  # do not overengeneer
  EMOJI = {
    '<img src="https://s.w.org/images/core/emoji/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
    '<img src="https://s.w.org/images/core/emoji/2/72x72/1f609.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":wink:",
    '<img src="https://s.w.org/images/core/emoji/72x72/1f642.png" alt="&#x1f609;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:",
    '<img src="https://s.w.org/images/core/emoji/2/72x72/1f642.png" alt="&#x1f642;" class="wp-smiley" style="height: 1em; max-height: 1em;" />' => ":simple_smile:"
  }

  def replace_emoji(post)
    EMOJI.each do |link, emoji|
      post.gsub!(link, emoji)
    end
  end

  def download_and_replace_images(post, download_dir)
    # replace images
    download_and_replace_tag(post, download_dir, "img", "src")
    # replace links to images
    download_and_replace_tag(post, download_dir, "a", "href")
  end

  # replace images by a local copy, download images if not already present
  def download_and_replace_tag(tree, download_dir, tag, attribute)
    # replace only URLs pointing to an uploaded content
    tree.xpath(".//#{tag}[contains(@#{attribute},\"//lizards.opensuse.org/wp-content/uploads\")]").each do |node|
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

  def download(url, file)
    puts "Downloading #{url}..."
    content = Net::HTTP.get(url)

    puts "Saving to #{file}"
    File.write(file, content)
  end

  def yaml_header(item)
    header = {
      # Note: 'description' is not present in HTML
      'layout' => 'post',
      'date' => post_date(item),
      'title' => post_title(item),
      # Note: the categories and tags must be fixed manually
      # both are mixed into a single list
      'category' => post_tags(item),
      'tags' => post_tags(item)
    }

    header.to_yaml
  end

  # post file name
  def post_file_name(post)
    name = post_title(post).split(%r{ |!|’|/|:|&|-|$|,|\(|\)}).map do |i|
      i.downcase if i != ''
    end

    name.compact.join('-')
  end

  # get the date from the post permalink
  def post_date(post)
    post_link = post.xpath("h2/a").first.attribute("href").to_s

    if post_link =~ /lizards\.opensuse\.org\/([0-9]{4}\/[0-9]{2}\/[0-9]{2})\//
      return Date.parse(Regexp.last_match[1])
    end

    nil
  end

  # get the post tags ans categories
  def post_tags(post)
    post.xpath("p[@class=\"postmetadata\"]/a[@rel=\"category tag\"]").map(&:text)
  end

  # get the post title
  def post_title(post)
    post.xpath("h2/a").first.text
  end

  # delete unused attributes
  def attributes_cleanup(node)
    node.delete("width")
    node.delete("height")
    node.delete("class")
    node.delete("srcset")
    node.delete("sizes")
  end
end
