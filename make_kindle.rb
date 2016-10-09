require 'rubima'
require 'kindle'
require 'cgi'
require 'pp'

def make_nav(title, file, children)
  sub = []
  children.each do |node|
    sub << Kindle::NavElement.new(node.title, node.link)
  end
  Kindle::NavElement.new(title, file, sub)
end

def make_kindle(vol)
  spine_files = []
  nav_items = []
  
  # top_fileが2つ以上の場合Rubyの歩き方は末尾に移動する削除するか
  if vol == 'all'
    top_file = (1..54).map { |x| "%04d.html" % x }
    delete_firststep = true
    spine_files << 'index.html'
  else
    top_file = [ "#{vol}.html" ]
    delete_firststep = false
  end
  
  top_file.each do |file|
    title, links = Rubima.get_toplink(file)
    pp title
    pp links
    spine_files << file
    if delete_firststep
      links = links.delete_if { |link| link.link == 'FirstStepRuby.html' }
    end
    links.each do |link|
      spine_files << link.link
    end
    nav_items << make_nav(title, file, links)
  end
  if delete_firststep
    nav_items << Kindle::NavElement.new('Ruby の歩き方', 'FirstStepRuby.html')
    spine_files << 'FirstStepRuby.html'
  end
  puts spine_files
  Kindle::Nav.new('ja', nav_items).write('nav.xhtml')

  items = []
  ids   = []
  spine_files.each do |file|
    id = Kindle::BookItem.get_id(file)
    next if id
    item = Kindle::BookItem.new(file)
    items << item
    ids << item.id
  end
  
  files = Rubima::parse_filelink(spine_files)
  files.delete(nil)
  files.each do |file|
    items << Kindle::BookItem.new(file)
  end
  info = Kindle::BookInfo.new(
    'Rubist Magazin for for Kindle',
    'るびま 創刊号',
    'ja', 'cover.png', '00000000')
  
  Kindle::Opf.new(info, items, ids).write('rubima.opf')
end

exit if ARGV.empty?
vol = ARGV[0]
make_kindle(vol)
