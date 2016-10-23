require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'pp'

module Rubima
  RUBIMA_HOME = 'http://magazine.rubyist.net'
  REJECT_REF  = /^(http|ftp|mailto|file|\/\/)/
  SKIP_FILE   = /\.(zip|pdf|xls|mdb|csv|aia|gz|ckd)$/i 
  WAIT_TIME   = 1 # wait between download from rubima site

  Link = Struct.new(:title, :link, :file)

  module DL
    # retrieve <a> and <img> from html data
    def self.scan_tag(data)
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
          sleep WAIT_TIME
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
  
  module Setup
    def self.unescape_name(name)
      ret = name
      if name =~ /%\h\h/
        ret = name.gsub(/(%\h\h)+/) do |str|
          s = str[1..-1].split(/%/).map(&:hex).pack('c*')
          s.force_encoding('utf-8')
          s.gsub(/\+/, '_')
        end
      end
      ret.tr('+ ', '_')
    end
    
    def self.fix_header(doc)
      paths = %w(
        /html/head/meta[@http-equiv="Content-Script-Type"]
        /html/head/link[@rel="alternate"]
        /html/head/link[@rel="icon"]
        /html/head/link[@href="/favicon.ico"]
        /html/head/style
        //script
        //embed
        //object).join('|')
      doc.xpath(paths).each { |node| node.unlink }
    end
    
    def self.fix_main(doc)
      footnote = doc.xpath('//div[@class="footnote"]')
      main = doc.xpath('/html/body/div/div[@class="contents"]/div[@class="main"]')
      
      paths = %w(
        div[@class="adminmenu"]
        div/div[@class="social-buttons"]
        //div[@class="sidebar"]
        //div[@class="comment"]
        div[last()]
        ).join('|')
      main.xpath(paths).each { |node| node.unlink }
      main.push(footnote[0]) unless footnote.empty?
    
      # おねがい以降を削除
      delete_flag = false
      main.xpath('//div[@class="section"]/*').each do |node|
        delete_flag = true if node.name == 'h3' && node.text.strip == 'おねがい'
        node.unlink if delete_flag
      end
    
      # replace main part
      doc.xpath('/html/body/*').each { |node| node.unlink }
      doc.xpath('/html/body')[0].add_child(main)
    end
    
    def self.modify_link(doc)
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
    
    def self.replace_link(doc, filename_table)
      reject = /^(http|ftp|mailto|file|\/\/)/
      doc.xpath('//a[@href]').each do |node|
        link = node['href']
        next if link =~ reject || link[0] == '#'
        ref, id = link.split(/#/)
        file = filename_table[Rubima::get_name(ref)]
        file += '#' + id if id
        unless link == file
          node['href'] = file
          # puts "#{link} -> #{file}"
        end
      end
      doc.xpath('//img[@src]').each do |node|
        link = node['src']
        next if link =~ reject
        file = filename_table[Rubima::get_name(link)]
        unless link == file
          node['src'] = file 
          # puts "#{link} -> #{file}"
        end
      end
    end
    
    def self.fix_html(html, filename_table)
      doc = Nokogiri::HTML.parse(html)
      
      fix_header(doc)
      fix_main(doc)
      
      # replace link
      modify_link(doc)
      replace_link(doc, filename_table)
    
      doc.to_html
    end
  end
  
  
  # convert link to valid filename
  def self.get_name(link)
    link.sub(%r|^(\./)?\?|, '')
         .sub(/c=plugin;plugin=attach_download;/, '')
         .sub(/file_name=/, 'f=')
         .gsub(/;/, '_')
  end
  
  def self.skip_file?(file)
    file =~ SKIP_FILE
  end

  def self.html_file?(file)
    data = open(file, 'rb').read(16)
    data =~ /^<!DOCTYPE/
  end

  def self.get_toplink(file)
    html = open(file, 'r:utf-8', &:read)
    doc = Nokogiri::HTML.parse(html)
    links = []
    doc.xpath('//h3').each do |node|
      text = node.text.tr("\u3000", ' ')
      node.xpath('a[@href]').each do |tag|
        ref = tag['href']
        links << Link.new(text, ref) unless ref =~ REJECT_REF
      end
    end
    [doc.xpath('//h1')[0].text, links]
  end

  def self.parse_filelink(files)
    links = []
    done = {}
    rest = files.dup
    until rest.empty?
      file = rest.shift
      next if done[file]
      done[file] = true
      next unless file =~ /\.html$/i
      puts file
      html = open(file, 'r:utf-8', &:read)
      doc = Nokogiri::HTML.parse(html)
      %w(a href img src).each_slice(2) do |tag, attr|
        doc.xpath("//#{tag}[@#{attr}]").each do |node|
          ref, _ = node[attr].split(/#/)
          next if !ref || ref.empty?
          if ref !~ REJECT_REF && !done[done]
            puts "# #{ref.inspect}"
            links << ref
            rest << ref 
          end
        end
      end
    end
    links.uniq
  end
end
