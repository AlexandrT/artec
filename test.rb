require 'nokogiri'
require 'httparty'
require 'yard'

class Loader
  include HTTParty

  headers 'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)'
  base_uri 'qa-web-test-task.s3-website.eu-central-1.amazonaws.com'

  # Load page by url
  # @param url [String] path of URL's
  # @return [Nokogiri::HTML::Document, nil] loaded page or nil
  #   if the response code is not equal 200
  # @example
  #   load_page("/1.html")
  def load_page(url)
    response = self.class.get(url)
    page = nil

    code = response.code.to_i
    case code
    when 500..599
      puts "[ERR]: Server error #{code}"
    when 200
      page = Nokogiri::HTML(response.body, nil, 'utf-8')
    else
      puts "Strange response code during list load - #{code}"
    end

    page
  end
end

class Parser
  attr_accessor :visited_urls

  def initialize
    self.visited_urls = Array.new
  end

  # Check links on the page
  # @param page [Nokogiri::HTML::Document]
  # @return [String, nil] href from the link or nil
  #   if page contain zero or more than one links
  # @example
  #   check_next(page)
  def check_next(page)
    href = nil
    links = page.xpath("//a/@href")

    if links.length == 1
      href = links.first.value
    elsif links.length == 0
      puts "No links in the page"
    else
      puts "More than one link in the page"
    end

    href
  end

  # Check page by word "последняя"
  # @param page [Nokogiri::HTML::Document]
  # @return [Boolean] true if the page is contains "последняя"
  #   else return false
  # @example
  #   check_last(page)
  def check_last(page)
    if page.content =~ /последняя/i
      return true
    end

    false
  end

  # Check that current url was not already visited
  # @param url [String]
  # @return [Boolean] false if url was not visited
  # @example
  #   check_visited("/2.html")
  def check_visited(url)
    is_visited = self.visited_urls.include? url
    self.visited_urls.push(url)
    is_visited
  end
end

loader = Loader.new
parser = Parser.new

i = 1
is_last = false

begin
  url = '/' + i.to_s + '.html'
  is_visited = parser.check_visited(url)

  page = loader.load_page(url)

  if page.nil?
    puts "Returns empty page by URL: #{url}"
    break
  end

  next_page_link = parser.check_next(page)
  puts url if next_page_link.nil?

  is_last = true if parser.check_last(page)

  i = i + 1
end while not is_last and not is_visited

puts "The last page is #{url}"
