require 'nokogiri'
require 'open-uri'

HOME = 'http://magazine.rubyist.net'
Link = Struct.new(:link, :text, :file)

# load taregt from local file or rubima site
def load_file(target)
  file = get_name(target)
  begin
    if File.exist?(file)
      puts "# load local #{file}"
      data = open(file, 'rb', &:read)
    else
      p target
      puts "# load net #{HOME}/#{target}"
      data = open("#{HOME}/#{target}", 'rb', &:read)
      sleep 0.5
    end
  rescue
    puts $!
    data = ''
 end
  data
end

# retrieve links from index.html
def load_index
  file = 'index.html'
  html = load_file(file)
  doc = Nokogiri::HTML.parse(html)
  open(file, 'wb').write(html) unless File.exist?(file)
  
  links = {}
  doc.xpath('//div[@class="body"]/div[@class="section"]/ul[1]/li/a').each do |node|
    ref = node['href']
    links[ref] = Link.new(ref, node.text)
  end
  links
end

# retrieve <a> and <img> from html data
def parse_ref(data)
  reject = /^(http|ftp|mailto|file|\/\/)/
  links = {}
  doc = Nokogiri::HTML.parse(data)
  %w(a href img src).each_slice(2) do |tag, attr|
    doc.xpath("//#{tag.to_s}[@#{attr}]").each do |node|
      ref = node[attr]
     links[ref] = Link.new(ref, node.text) unless ref =~ reject
    end
  end
  #doc.xpath('//a[@href]').each do |node|
  links
end

# convert link to valid filename
def get_name(link)
  link.sub(%r|^(\./)?\?|, '')
       .sub(/c=plugin;plugin=attach_download;/, '')
       .sub(/file_name=/, 'f=')
       .gsub(/;/, '_')
end

# load additional file
def load_additional
  %w(hiki_base.css
     rubima/rubima.css
     rubima/rubima_logo_l.png
     rubima/rubima_logo_left.png
     rubima/rubima_sidebar.png).each do |target|
    file = 'theme/' + target
    unless File.exist?(file)
      data = load_file(file)
      open(file, 'wb').write(data)
    end
  end
end

# == start of main
rest = load_index
done = { 'index.html' => '' }

until rest.empty?
  puts "#{done.size} / #{rest.size}"
  target, item = rest.shift
  
  target = 'index.html' if target == './'
  next if target =~ /^(http|ftp|mailto|\.\/\?c=(diff|login|search)|#)/
  target = target.split(/#/)[0]
  next if done.key?(target)
  puts "# process #{target}"
  
  data = load_file(target)
  file = get_name(target)
  
  # save it
  unless File.exist?(file)
    puts "# save to #{file}"
    open(file, 'wb').write(data) 
    item.file = file
  end
  
  # parse it if it's html
  if data =~ /^<!DOCTYPE/
    puts "# parse #{file}"
    links = parse_ref(data)
    puts "# got #{links.size} links"
    rest.merge!(links)
  end
  done[target] = item
end

load_additional
