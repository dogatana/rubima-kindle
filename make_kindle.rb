require 'rubima'
require 'kindle'
require 'pp'

def make_nav(title, file, children)
  sub = []
  children.each do |node|
    sub << Kindle::NavElement.new(node.title, node.link)
  end
  Kindle::NavElement.new(title, file, sub)
end

def make_kindle(vol)

  #top_file = Dir.glob('kindle/????html')
  top_file = [ "kindle/#{vol}.html" ]
  spine_files = []
  nav_items = []
  
  top_file.each do |file|
    title, link = Rubima.get_link(file)
    puts title, link
    spine_files << File.basename(file)
    link.each { |lnk| spine_files << lnk.link }
    nav_items << make_nav(title, File.basename(file), link)
    puts file
    break if file =~ /0010/
  end
  
  #puts spine_files
  #pp nav_items[0]
  
  Kindle::Nav.new('ja', nav_items).write('kindle/nav.xhtml')
  
  items = []
  ids   = []
  spine_files.each do |file|
    item = Kindle::BookItem.new(file)
    items << item
    ids << item.id
  end
  
  files = Dir.glob("kindle/#{vol}.*")
  files += Dir.glob('kindle/theme/**/*')
=begin
  files = Dir.glob('kindle/**/*')
             .delete_if do |f|
                File.directory?(f) ||
                f =~ /(zip|xls|gz|ckd|mdb|x|pdf|aia|Brushup|Preview)$/
              end
             .map { |f| f.sub(/^kindle\//, '') }
=end
  files = files.map { |f| f.sub(/^kindle\//, '') }
  puts files
  
  files -= spine_files + ['rubima.opf', 'rubima.mobi', 'cover.png', 'nav.xhtml']
  # puts files
  files.each { |file| items << Kindle::BookItem.new(file) }
  
  info = Kindle::BookInfo.new(
    'Rubist Magazin for for Kindle',
    'るびま 創刊号',
    'ja', 'cover.png', '00000000')
  
  Kindle::Opf.new(info, items, ids).write('kindle/rubima.opf')
end

exit if ARGV.empty?
vol = ARGV[0]
make_kindle(vol)
