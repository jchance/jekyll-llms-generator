# frozen_string_literal: true

require "minitest/autorun"
require "jekyll"
require_relative "../lib/jekyll/llms_txt_generator"

class LlmsTxtGeneratorTest < Minitest::Test
  def setup
    @site = mock_site
    @generator = Jekyll::LlmsTxtGenerator.new
  end

  # --- Helper: build a minimal mock site ---

  def mock_site(config_override = {})
    base_config = Jekyll::Configuration::DEFAULTS.merge(
      "url"      => "https://example.com",
      "baseurl"  => "",
      "title"    => "Test Site",
      "llms_txt" => {
        "title"   => "Test Site",
        "tagline" => "A tagline.",
        "sections" => [
          { "title" => "Posts", "collection" => "posts" }
        ]
      }.merge(config_override.delete("llms_txt") || {})
    ).merge(config_override)

    site = Jekyll::Site.new(Jekyll.configuration(base_config))
    site
  end

  def make_doc(title:, url:, content: "", date: Time.now, description: nil, llms_txt: nil)
    doc = Struct.new(:data, :url, :content, :excerpt) do
      def output; content; end
    end
    data = { "title" => title, "date" => date }
    data["description"] = description if description
    data["llms_txt"] = llms_txt unless llms_txt.nil?
    doc.new(data, url, content, nil)
  end

  # --- Tests ---

  def test_generator_has_low_priority
    assert_equal :low, Jekyll::LlmsTxtGenerator.priority
  end

  def test_generator_is_safe
    assert Jekyll::LlmsTxtGenerator.safe
  end

  def test_strip_html_basic
    g = Jekyll::LlmsTxtGenerator.new
    assert_equal "Hello World", g.send(:strip_html, "<p>Hello <strong>World</strong></p>")
  end

  def test_strip_html_removes_scripts
    g = Jekyll::LlmsTxtGenerator.new
    html = "<p>Text</p><script>alert('xss')</script><p>More</p>"
    result = g.send(:strip_html, html)
    refute_includes result, "alert"
    assert_includes result, "Text"
  end

  def test_strip_html_decodes_entities
    g = Jekyll::LlmsTxtGenerator.new
    result = g.send(:strip_html, "&amp; &lt; &gt; &quot; &#39;")
    assert_equal "& < > \" '", result
  end

  def test_strip_html_nil_returns_empty
    g = Jekyll::LlmsTxtGenerator.new
    assert_equal "", g.send(:strip_html, nil)
  end

  def test_site_base_url_no_baseurl
    g = Jekyll::LlmsTxtGenerator.new
    config = { "url" => "https://example.com", "baseurl" => "" }
    g.instance_variable_set(:@site, Struct.new(:config).new(config))
    assert_equal "https://example.com", g.send(:site_base_url)
  end

  def test_site_base_url_with_baseurl
    g = Jekyll::LlmsTxtGenerator.new
    config = { "url" => "https://example.com", "baseurl" => "/blog" }
    g.instance_variable_set(:@site, Struct.new(:config).new(config))
    assert_equal "https://example.com/blog", g.send(:site_base_url)
  end

  def test_doc_to_item_basic
    g = Jekyll::LlmsTxtGenerator.new
    config = { "url" => "https://example.com", "baseurl" => "" }
    g.instance_variable_set(:@site, Struct.new(:config).new(config))
    doc = make_doc(title: "My Post", url: "/2024/my-post/")
    item = g.send(:doc_to_item, doc)
    assert_equal "My Post", item[:title]
    assert_equal "https://example.com/2024/my-post/", item[:url]
  end

  def test_doc_to_item_uses_description
    g = Jekyll::LlmsTxtGenerator.new
    config = { "url" => "https://example.com", "baseurl" => "" }
    g.instance_variable_set(:@site, Struct.new(:config).new(config))
    doc = make_doc(title: "Post", url: "/post/", description: "A great article.")
    item = g.send(:doc_to_item, doc)
    assert_equal "A great article.", item[:description]
  end

  def test_format_item_with_description
    g = Jekyll::LlmsTxtGenerator.new
    item = { title: "My Post", url: "https://example.com/post/", description: "A summary." }
    line = g.send(:format_item, item)
    assert_equal "- [My Post](https://example.com/post/): A summary.", line
  end

  def test_format_item_without_description
    g = Jekyll::LlmsTxtGenerator.new
    item = { title: "My Post", url: "https://example.com/post/", description: nil }
    line = g.send(:format_item, item)
    assert_equal "- [My Post](https://example.com/post/)", line
  end

  def test_items_from_collection_filters_opt_out
    g = Jekyll::LlmsTxtGenerator.new

    doc1 = make_doc(title: "Included", url: "/a/")
    doc2 = make_doc(title: "Excluded", url: "/b/", llms_txt: false)

    posts_collection = Struct.new(:docs).new([doc1, doc2])
    site_struct = Struct.new(:posts, :collections, :config).new(
      posts_collection, {}, "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)

    items = g.send(:items_from_collection, "posts")
    titles = items.map { |i| i[:title] }
    assert_includes titles, "Included"
    refute_includes titles, "Excluded"
  end

  def test_items_from_collection_limit
    g = Jekyll::LlmsTxtGenerator.new

    docs = (1..10).map { |i| make_doc(title: "Post #{i}", url: "/p#{i}/", date: Time.now - i) }
    posts_collection = Struct.new(:docs).new(docs)
    site_struct = Struct.new(:posts, :collections, :config).new(
      posts_collection, {}, "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)

    items = g.send(:items_from_collection, "posts", 3)
    assert_equal 3, items.length
  end

  def test_items_from_collection_sorted_newest_first
    g = Jekyll::LlmsTxtGenerator.new

    doc_old = make_doc(title: "Old", url: "/old/", date: Time.now - 86400)
    doc_new = make_doc(title: "New", url: "/new/", date: Time.now)
    posts_collection = Struct.new(:docs).new([doc_old, doc_new])
    site_struct = Struct.new(:posts, :collections, :config).new(
      posts_collection, {}, "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)

    items = g.send(:items_from_collection, "posts")
    assert_equal "New", items.first[:title]
    assert_equal "Old", items.last[:title]
  end

  def test_items_from_unknown_collection_returns_empty
    g = Jekyll::LlmsTxtGenerator.new
    posts_collection = Struct.new(:docs).new([])
    site_struct = Struct.new(:posts, :collections, :config).new(
      posts_collection, {}, "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)
    items = g.send(:items_from_collection, "nonexistent")
    assert_empty items
  end

  def test_build_llms_txt_includes_title
    g = Jekyll::LlmsTxtGenerator.new
    posts_collection = Struct.new(:docs).new([])
    site_struct = Struct.new(:posts, :collections, :pages, :config).new(
      posts_collection, {}, [], "url" => "https://example.com", "baseurl" => "", "title" => "My Site"
    )
    g.instance_variable_set(:@site, site_struct)
    g.instance_variable_set(:@config, {
      "title" => "My Site",
      "tagline" => "Best site ever.",
      "sections" => []
    })
    result = g.send(:build_llms_txt)
    assert_includes result, "# My Site"
    assert_includes result, "> Best site ever."
  end

  def test_build_llms_txt_includes_intro
    g = Jekyll::LlmsTxtGenerator.new
    posts_collection = Struct.new(:docs).new([])
    site_struct = Struct.new(:posts, :collections, :pages, :config).new(
      posts_collection, {}, [], "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)
    g.instance_variable_set(:@config, {
      "title" => "Site",
      "intro" => "This is the intro paragraph.",
      "sections" => []
    })
    result = g.send(:build_llms_txt)
    assert_includes result, "This is the intro paragraph."
  end

  def test_collect_section_items_empty_when_no_config
    g = Jekyll::LlmsTxtGenerator.new
    posts_collection = Struct.new(:docs).new([])
    site_struct = Struct.new(:posts, :collections, :pages, :config).new(
      posts_collection, {}, [], "url" => "https://example.com", "baseurl" => ""
    )
    g.instance_variable_set(:@site, site_struct)
    items = g.send(:collect_section_items, { "title" => "Empty" })
    assert_empty items
  end

  def test_write_file_creates_file
    require "tmpdir"
    Dir.mktmpdir do |tmpdir|
      site_struct = Struct.new(:config, :dest) do
        def in_dest_dir(path)
          File.join(dest, path)
        end
      end.new({}, tmpdir)

      g = Jekyll::LlmsTxtGenerator.new
      g.instance_variable_set(:@site, site_struct)
      g.send(:write_file, "llms.txt", "# Hello\n")

      assert File.exist?(File.join(tmpdir, "llms.txt"))
      assert_equal "# Hello\n", File.read(File.join(tmpdir, "llms.txt"))
    end
  end
end
