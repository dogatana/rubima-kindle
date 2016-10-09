require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'pp'

module Rubima
  RUBIMA_HOME = 'http://magazine.rubyist.net'
  REJECT_REF = /^(http|ftp|mailto|file|\/\/)/

  Link = Struct.new(:title, :link, :file)

  module DL
    # load taregt from local file or rubima site
    def self.load_file(target)
      file = Rubima::get_name(target)
      begin
        if File.exist?(file)
          puts "# load(local) #{file}"
          data = open(file, 'rb', &:read)
        else
          puts "# load(net) #{RUBIMA_HOME}/#{target}"
          data = open("#{RUBIMA_HOME}/#{target}", 'rb', &:read)
          sleep 0.5
        end
      rescue
        puts $!
        data = ''
     end
      data
    end
    
    # retrieve links from index.html
    def self.get_master_index(file)
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
  
    # load additional file
    def self.load_additional_file
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
  end
  
  # retrieve <a> and <img> from html data
  def self.parse_ref(data)
    links = {}
    doc = Nokogiri::HTML.parse(data)
    %w(a href img src).each_slice(2) do |tag, attr|
      doc.xpath("//#{tag}[@#{attr}]").each do |node|
        ref = node[attr]
        unless ref =~ REJECT_REF
          links[ref] = Link.new(ref, node.text)
        end
      end
    end
    links
  end
  
  # convert link to valid filename
  def self.get_name(link)
    link.sub(%r|^(\./)?\?|, '')
         .sub(/c=plugin;plugin=attach_download;/, '')
         .sub(/file_name=/, 'f=')
         .gsub(/;/, '_')
  end
  
  SKIP_FILE = /\.(zip|pdf|xls|mdb|csv|aia|gz|ckd)$/i 
  def self.skip_file?(file)
    file =~ SKIP_FILE
  end

  def self.html_file?(file)
    data = open(file, 'rb').read(16)
    data =~ /^<!DOCTYPE/
  end

  def self.convert_name(name, escape)
    return name unless name =~ /^index.html/
    name = CGI.unescape(name) if escape
    base, id = name.split(/#/)
    new_base = base.sub(/^index\.html@/, '')
                   .gsub(/(c=login|c=plugin;plugin=attach_download);p=/, '')
                   .sub(/;file_name=/, '_')
    if new_base == '0006-CGIKit-2.x' || File.extname(new_base).empty?
      new_base += ".html"
    end
    new_base += '#' + id if id 
    new_base
  end

  def self.get_link(file)
    html = ''
    File.open(file, 'r:utf-8') do |f|
      html = f.read
      f.close
    end
    doc = Nokogiri::HTML.parse(html)
    link = []
    doc.xpath('//h3').each do |node|
      text = node.text.tr("\u3000", ' ').strip
      atag = node.xpath('a[@href]')[0]
      if atag && atag['href'] !~ /^http/
        link << Link.new(text, convert_name(atag['href'], false))
      end
    end
    [doc.xpath('//h1')[0].text, link]
  end

  def self.unlink_tag(doc)
    # amazon書籍のサムネイル画像
    doc.xpath('//img[@src]').each do |node|
      link = node['src']
      node.unlink if link =~ %r|^http://ecx.images-amazon.com/|
    end
    # リンクを削除し、テキストのみ残す
    doc.xpath('//a[@href]').each do |node|
      link = node['href']
      if link =~ SKIP_FILE
        node.after node.text
        node.unlink
      end
    end
  end

  def self.fix_file(file)
    html = ''
    File.open(file, 'r:utf-8') do |f|
      html = f.read
      f.close
    end
    doc = Nokogiri::HTML.parse(html)

    title = doc.xpath('//title')[0]
    if title && title.text.strip =~ / - Error$/
      return nil
    end
    # fix header and ohters
    paths = %w(
      /html/head/meta[@http-equiv="Content-Script-Type"]
      /html/head/link[@rel="alternate"]
      /html/head/link[@rel="icon"]
      /html/head/link[@href="/favicon.ico"]
      /html/head/style
      //script).join('|')
    doc.xpath(paths).each { |node| node.unlink }

    doc.xpath('//img[@alt="u26.gif"]').each do |img|
      img.attribute('alt').unlink
      # img['src'] = 'u26.gif'
    end

    footnote = doc.xpath('//div[@class="footnote"]')

    # fix main part
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

    unlink_tag(doc)

    # replace main part
    doc.xpath('/html/body/*').each { |node| node.unlink }
    doc.xpath('/html/body')[0].add_child(main)
    doc.xpath('//a[@href]').each do |node|
      link = node['href']
      node['href'] = convert_name(link, true)
    end
    doc.xpath('//img[@src]').each do |node|
      link = node['src']
      node['src'] = convert_name(link, true)
    end
    doc.to_html.gsub(/^\s+$/, '').gsub(/\n+/, "\n")
  end
end
