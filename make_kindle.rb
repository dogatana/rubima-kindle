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

  if vol == 'all'
    top_file = (1..54).map { |x| "kindle/%04d.html" % x }
  else
    top_file = [ "kindle/#{vol}.html" ]
  end
  spine_files = []
  nav_items = []
  
  # top_fileが2つ以上の場合Rubyの歩き方は末尾に移動する削除するか
  delete_firststep = top_file.size > 1
  top_file.each do |file|
    title, link = Rubima.get_link(file)
    spine_files << File.basename(file)
    if delete_firststep
      link = link.delete_if { |l| l.link == 'FirstStepRuby.html' }
    end
    link.each do |lk|
      link_file = CGI.unescape(lk.link)
      unless File.exist?('kindle/' + link_file)
        link_file += '.html' 
        raise "#{lk.link} not found" unless File.exist?('kindle/' + link_file)
        lk.link = link_file
      end
      spine_files << link_file
    end
    nav_items << make_nav(title, File.basename(file), link)
  end
  if delete_firststep
    nav_items << Kindle::NavElement.new('Ruby の歩き方', 'FirstStepRuby.html')
  end
  #puts spine_files
  #pp nav_items[0]
  
  Kindle::Nav.new('ja', nav_items).write('kindle/nav.xhtml')
  
  items = []
  ids   = []
  spine_files.each do |file|
    id = Kindle::BookItem.get_id(file)
    next if id
    item = Kindle::BookItem.new(file)
    items << item
    ids << item.id
  end
  
  files = Dir.glob("kindle/#{vol}*.*")
  files += Dir.glob('kindle/theme/**/*').delete_if { |f| File.directory?(f) }
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
