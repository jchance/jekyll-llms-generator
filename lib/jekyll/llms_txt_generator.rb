# frozen_string_literal: true

require "jekyll"

module Jekyll
  class LlmsTxtGenerator < Generator
    safe true
    priority :low

    def generate(site)
      @site = site
      @config = site.config["llms_txt"] || {}
      return unless @config["enabled"] != false

      # Store content on site object so the post_write hook can access it
      site.data["__llms_txt_content"] = build_llms_txt

      if @config["full"]
        site.data["__llms_full_txt_content"] = build_llms_full_txt
      end

      inject_link_tag(site) if @config["link_tag"] != false
    end

    private

    def site_base_url
      url = @site.config["url"].to_s.chomp("/")
      baseurl = @site.config["baseurl"].to_s.chomp("/")
      "#{url}#{baseurl}"
    end

    def build_llms_txt
      lines = []

      title = @config["title"] || @site.config["title"] || "Site"
      lines << "# #{title}"

      tagline = @config["tagline"] || @site.config["description"]
      lines << "\n> #{tagline}" if tagline && !tagline.empty?

      intro = @config["intro"]
      if intro && !intro.empty?
        lines << ""
        lines << intro.strip
      end

      sections = @config["sections"] || []
      sections.each do |section|
        items = collect_section_items(section)
        next if items.empty?

        lines << ""
        lines << "## #{section["title"]}"
        items.each do |item|
          lines << format_item(item)
        end
      end

      lines.join("\n") + "\n"
    end

    def build_llms_full_txt
      lines = []

      title = @config["title"] || @site.config["title"] || "Site"
      lines << "# #{title}"

      tagline = @config["tagline"] || @site.config["description"]
      lines << "\n> #{tagline}" if tagline && !tagline.empty?

      intro = @config["intro"]
      if intro && !intro.empty?
        lines << ""
        lines << intro.strip
      end

      sections = @config["sections"] || []
      sections.each do |section|
        items = collect_section_items(section)
        next if items.empty?

        lines << ""
        lines << "## #{section["title"]}"
        items.each do |item|
          lines << format_item_full(item)
        end
      end

      lines.join("\n") + "\n"
    end

    def collect_section_items(section)
      items = []

      if section["collection"]
        items += items_from_collection(section["collection"], section["limit"])
      end

      if section["pages"]
        items += items_from_pages(section["pages"])
      end

      items
    end

    def items_from_collection(collection_name, limit = nil)
      docs = if collection_name == "posts"
               @site.posts.docs
             elsif @site.collections[collection_name]
               @site.collections[collection_name].docs
             else
               []
             end

      docs = docs.reject { |d| d.data["llms_txt"] == false }
      docs = docs.sort_by { |d| d.data["date"] || Time.now }.reverse
      docs = docs.first(limit) if limit

      docs.map { |d| doc_to_item(d) }
    end

    def items_from_pages(page_urls)
      page_urls.filter_map do |url|
        page = @site.pages.find { |p| p.url == url || p.url == "#{url}index.html" }
        next if page.nil?
        next if page.data["llms_txt"] == false

        {
          title: page.data["title"] || page.url,
          url: "#{site_base_url}#{page.url}",
          description: page.data["description"] || page.data["excerpt"],
          content: page.content
        }
      end
    end

    def doc_to_item(doc)
      description = doc.data["description"] ||
                    doc.data["tagline"] ||
                    (doc.data["excerpt"]&.output ? strip_html(doc.data["excerpt"].output) : nil) ||
                    (doc.excerpt ? strip_html(doc.excerpt.output) : nil)

      {
        title: doc.data["title"],
        url: "#{site_base_url}#{doc.url}",
        description: description&.strip&.gsub(/\s+/, " ")&.slice(0, 200),
        content: doc.content
      }
    end

    def format_item(item)
      line = "- [#{item[:title]}](#{item[:url]})"
      desc = item[:description]
      line += ": #{desc}" if desc && !desc.empty?
      line
    end

    def format_item_full(item)
      lines = []
      lines << "- [#{item[:title]}](#{item[:url]})"
      if item[:content] && !item[:content].empty?
        stripped = strip_html(item[:content]).strip.gsub(/\s+/, " ")
        lines << "" << stripped << ""
      end
      lines.join("\n")
    end

    def strip_html(html)
      return "" unless html

      html.gsub(/<script[^>]*>.*?<\/script>/mi, "")
          .gsub(/<style[^>]*>.*?<\/style>/mi, "")
          .gsub(/<[^>]+>/, " ")
          .gsub(/&nbsp;/, " ")
          .gsub(/&amp;/, "&")
          .gsub(/&lt;/, "<")
          .gsub(/&gt;/, ">")
          .gsub(/&quot;/, '"')
          .gsub(/&#39;/, "'")
          .gsub(/\s+/, " ")
          .strip
    end

    def write_file(filename, content)
      dest = @site.in_dest_dir(filename)
      FileUtils.mkdir_p(File.dirname(dest))
      File.write(dest, content)
    end

    def inject_link_tag(site)
      llms_url = "#{site_base_url}/llms.txt"
      site.pages.each do |page|
        next unless page.output_ext == ".html"

        page.content = page.content.to_s.sub(
          %r{</head>}i,
          %(<link rel="ai" href="#{llms_url}" />\n</head>)
        )
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  content = site.data.delete("__llms_txt_content")
  if content
    dest = site.in_dest_dir("llms.txt")
    FileUtils.mkdir_p(File.dirname(dest))
    File.write(dest, content)
  end

  full_content = site.data.delete("__llms_full_txt_content")
  if full_content
    dest = site.in_dest_dir("llms-full.txt")
    FileUtils.mkdir_p(File.dirname(dest))
    File.write(dest, full_content)
  end
end
