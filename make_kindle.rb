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

def make_kindle(tops)
  spine_files = tops.dup
  
  tops.each do |file|
    p file
    _, links = Rubima.get_toplink(file)
    links.each do |link|
      spine_files << link.link
    end
  end
  spine_files.unshift 'kindle_index.html'
  
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

def make_navitems
  items = []
  top = Rubima::DL::get_master_index('index.html')
  top.keys.reverse.each do |file|
    title, links = Rubima::get_toplink(file)
    # 各号のRubyの歩き方を削除
    links.delete_if { |x| x.link == 'FirstStepRuby.html' }
    # 日本 Ruby 会議 2011 直前特集号 に 0035 号の記事が入っているのを削除
    links.delete_if { |x| x.link =~ /^0035/ } if file == 'preRubyKaigi2011.html'
    sub_items = links.inject([]) do |a, e|
                  a << Kindle::NavElement.new(e.title.strip, e.link)
                end
    items << Kindle::NavElement.new(title, file, sub_items)
  end
  items << Kindle::NavElement.new('Rubyの歩き方', 'FirstStepRuby.html')
  items
end

def make_index(file, items)
  html = Nokogiri::HTML::Builder.new(encoding: 'utf-8') do |doc|
    doc.html(lang: 'ja') do
      doc.head do
        doc.title('目次')
      end
      doc.body do 
        doc.h1('目次')
        doc.ul do
          items.each do |item|
            doc.li do
              doc.a(item.title, href: item.file)
              unless item.children.empty?
                doc.ul do
                  item.children.each do |sub_item|
                    doc.li { doc.a(sub_item.title, href: sub_item.file) }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  open(file, 'w:utf-8').write(html.to_html)
end

def make_spine(items)
  spines = []
  items.each do |item|
    spines << item.file
    item.children.each { |sub| spines << sub.file }
  end
  spines
end

nav_items = make_navitems
Kindle::Nav.new('ja', nav_items).write('nav.xhtml')
make_index('kindle_index.html', nav_items)
spines = make_spine(nav_items)
make_kindle(spines)
