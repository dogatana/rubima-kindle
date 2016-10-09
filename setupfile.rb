require 'rubima'
require 'fileutils'
require 'pp'

Link = Struct.new(:link, :text, :file)

def parse_ref(file)
  data = open(file, 'rb', &:read)
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

def decode(name)
  ret = name
  if name =~ /%\h\h/
    ret = name.gsub(/(%\h\h)+/) do |str|
      s = str[1..-1].split(/%/).map(&:hex).pack('c*')
      s.force_encoding('utf-8')
    end
  end
  ret
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

def get_name(link)
  link.sub(%r|^(\./)?\?|, '')
       .sub(/c=plugin;plugin=attach_download;/, '')
       .sub(/file_name=/, 'f=')
       .gsub(/;/, '_')
end

def replace_link(doc, file_rule)
  reject = /^(http|ftp|mailto|file|\/\/)/
  doc.xpath('//a[@href]').each do |node|
    link = node['href']
    next if link =~ reject || link[0] == '#'
    ref, id = link.split(/#/)
    file = file_rule[get_name(ref)]
    file += '#' + id if id
    unless link == file
      node['href'] = file
      puts "#{link} -> #{file}"
    end
  end
  doc.xpath('//img[@src]').each do |node|
    link = node['src']
    next if link =~ reject
    file = file_rule[get_name(link)]
    unless link == file
      node['src'] = file 
      puts "#{link} -> #{file}"
    end
  end
end

def get_name(link)
  link.sub(%r|^(\./)?\?|, '')
       .sub(/c=plugin;plugin=attach_download;/, '')
       .sub(/file_name=/, 'f=')
       .gsub(/;/, '_')
end

def fix_link(html, file_rule)
  doc = Nokogiri::HTML.parse(html)

  # fix header and ohters
  paths = %w(
    /html/head/meta[@http-equiv="Content-Script-Type"]
    /html/head/link[@rel="alternate"]
    /html/head/link[@rel="icon"]
    /html/head/link[@href="favicon.ico"]
    /html/head/style
    //script).join('|')
  doc.xpath(paths).each { |node| node.unlink }

  # fix main part
  footnote = doc.xpath('//div[@class="footnote"]')
  main = doc.xpath('/html/body/div/div[@class="contents"]/div[@class="main"]')
  paths = %w(
    div[@class="adminmenu"]
    div/div[@class="social-buttons"]
    //div[@class="sidebar"]
    div[last()]
    ).join('|')
  # 最終 div は (あれば）脚注のみとする
  main.xpath(paths).each { |node| node.unlink }
  main.push(footnote[0]) unless footnote.empty?

  # おねがい以降を削除
  delete_flag = false
  main.xpath('//div[@class="section"]/*').each do |node|
   delete_flag = true if node.name == 'h3' && node.text.strip == 'おねがい'
   node.unlink if delete_flag
  end

  Rubima.unlink_tag(doc)

  # replace main part
  doc.xpath('/html/body/*').each { |node| node.unlink }
  doc.xpath('/html/body')[0].add_child(main)
  
  # replace link
  replace_link(doc, file_rule)

  doc.to_html
end

# == start of main

file_rule = {}
Dir.glob('*').each do |file|
  next unless File.file?(file)
  new_file = decode(file)
  if Rubima.html_file?(file)
    new_file += '.html' unless new_file =~ /\.html$/i
    file_rule[file] = new_file
  else
    file_rule[file] = new_file
  end
end

file_rule.each do |file, new_file|
  if new_file =~ /\.html$/
    html = open(file, 'r:utf-8', &:read)
    new_html = fix_link(html, file_rule)
    puts new_html.size
    open("../fixed/#{new_file}", 'w:utf-8').write(new_html)
  else
    #FileUtils.cp(file, '../fixed/' + new_file)
  end
end


exit
=begin
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



rest = load_index


rule.select { |k, v| k != v }.each { |_, file| puts file }



exit
Dir.glob('*').each do |file|
  # zipファイルなどは対象外とする
  next if file =~ /@c=login/ || Rubima.skip_file?(file)
  # 壊れているjpgファイルを対象外とする（サーバがエラー html ファイルを返しているもの）
  next if file =~ /(jpe?g|png)$/i && Rubima.html_file?(file)

  base = File.basename(file)
  new_base = Rubima.convert_name(base, false)
  new_base += '.html' if new_base !~ /html$/ && Rubima.html_file?(file)

  #next unless new_base =~ /^\d+/
  new_file = 'kindle/' + new_base

  puts new_file
  if new_file =~ /html$/
    html = Rubima.fix_file(file)
    next unless html
    File.open(new_file, 'w:utf-8').write(html)
  else
    FileUtils.cp(file, new_file)
  end
end

# cssファイルなど
FileUtils.cp_r('magazine.rubyist.net/theme', 'kindle')
FileUtils.cp('kindle/theme/rubima/rubima_logo_l.png', 'kindle/cover.png')
FileUtils.cp('rubima.css', 'kindle/theme/rubima')
=end
