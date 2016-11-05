require 'nokogiri'
require 'fastimage'
require 'cgi'

def image_size(file)
  FastImage.new(file).size # [width, height]
end

def calc_size(factor, tag_width, tag_height, image_width, image_height)
  width = (tag_width == 0) ? image_width : tag_width
  height = (tag_height == 0) ? image_height : tag_height
  #puts "tag: #{tag_width} x #{tag_height}"
  #puts "image: #{image_width} x #{image_height}"

  return (width * factor).round, (height * factor).round
end


def magnify_image(file, factor)
  html = open(file, 'r:utf-8', &:read)

  doc = Nokogiri::HTML.parse(html)
  doc.xpath('//img').each do |node|
    image_file = CGI.unescape node['src']
    next if image_file.empty? || image_file =~ /^http/
    #puts image_file
    width, height = calc_size(factor,
                              node['width'].to_i, node['height'].to_i,
                              *image_size(image_file))
    node['width'] = width
    node['height'] = height
    #puts "magnify: #{width} x #{height}"
  end
  open(file, 'w:utf-8').write(doc.to_html)
end

exit(1) unless ARGV.size == 1

magnify_factor = ARGV[0].to_f
exit(1) if magnify_factor <= 1.0

Dir['*.html'].each do |file|
  puts "# process #{file}"
  magnify_image(file, magnify_factor)
end
