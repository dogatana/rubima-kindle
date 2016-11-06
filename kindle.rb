# Copyright (c) 2016 dogatana(Toshihiko Ichida)

require 'forwardable'
require 'cgi'

module Kindle

class NavElement
  attr_reader :title, :attr
  attr_accessor :file, :children
  def initialize(title, file = '', children = [], attr = '')
    @title = title
    @file = file
    @attr = attr
    @children = children
  end
  
  def to_s
    title = CGI.escape_html(@title)
    if @file.empty?
      "<span>#{title}</span>"
    else
      %Q[<a href="#{@file}" #{@attr}>#{title}</a>]
    end
  end

  def children?
    @children && !@children.empty?
  end
end

class Nav
  HEAD = <<EOS
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html 
  xmlns="http://www.w3.org/1997/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xml:lang="@lang@"
  lang="@lang@">
<head><title>Table of Contents</title></head>
<body>
<nav epub:type="toc">
<h1>目次</h1>
EOS

  TAIL = "\n</nav>\n</body>\n</html>"
  def initialize(lang, elements)
    @lang = lang
    @elements = elements
  end
  
  def write(file = 'nav.xhtml')
    File.open(file, 'w:utf-8') do |f|
      f.print HEAD.gsub(/@lang@/, @lang)
      write_elements(f, 0, @elements)
      f.puts TAIL
      f.close
    end
  end

  private
  def write_elements(f, level, elements)
    spc = ' ' * (level * 2)
    f.puts "#{spc}<ol>"
    elements.each do |e|
      unless e.children?
        f.puts "#{spc}  <li>#{e}</li>"
        next
      end
      f.puts "#{spc}  <li>#{e}"
      write_elements(f, level + 1, e.children)
      f.puts "#{spc}  </li>"
    end
    f.puts "#{spc}</ol>"
  end

  def write_elements2(f, level, elements)
    spc = ' ' * (level * 2)
    f.puts "\n#{spc}<ol>"
    is_first = true
    elements.each do |e|
      if e.is_a?(Array)
        write_elements(f, level + 1, e)
      else
        f.puts '</li>' unless is_first
        f.print "#{spc}<li>"
        f.print e.to_s
      end
      is_first = false if is_first
    end
    f.print "</li>\n#{spc}</ol>"
  end

end

BookInfo = Struct.new(:title, :author, :lang, :cover, :uuid)

class FileIdManager
  extend Forwardable
  
  def initialize
    @serial = 1
    @files = {}
  end
  
  def add(file, id)
    unless id
      id = "id#@serial" 
      @serial += 1
    end
    @files[file] = id
  end

  def_delegators :@files, :'key?', :[], :each, :keys, :vaules
end

class BookItem
  def self.idman
    @man ||= FileIdManager.new
  end
  
  def self.get_id(file)
    @man ||= FileIdManager.new
    @man[file]
  end
  
  def self.add(file, id)
    @man.add(file, id)
  end
  
  attr_reader :id, :name, :type
  def initialize(name, id = nil, type = nil)
    @name = name
    @id = BookItem.add(name, id)
    @type = type || file_type(name)
  end
  
  def file_type(name)
    case File.extname(name).downcase
    when '.html'
      'text/html'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.gif'
      'image/gif'
    when '.png'
      'image/png'
    when '.xhtml'
      'application/xhtml+xml'
    when '.xml'
      'text/plain'
    when '.css'
      'text/css'
    else # default は text/plain とする
      'text/plain'
    end
  end
  
  def to_s
    ret = %Q[    <item id="#{id}" media-type="#{type}" href="#{name}" />]
    ret.sub!(%r! />!, ' properties="nav" />') if id == 'nav'
    ret.sub!(%r! />!, ' properties="cover-image" />') if id == 'cimage'
    ret
  end
end


class Opf
  def initialize(info, items, spine)
    @info, @items, @spine = info, items, spine
  end

  def write(file)
    File.open(file, 'w:utf-8') do |f|
      f.puts head
      f.puts metadata
      f.puts
      f.puts manifest
      f.puts
      f.puts spine
      f.puts
      f.puts tail
      f.close
    end
  end

HEAD = <<EOS_HEAD
<?xml version="1.0" encoding="utf-8"?>
<package
  unique-identifier="book-id"
  xmlns="http://www.idpf.org/2007/opf"
  version="3.0"
  xml:lang="@lang@">
EOS_HEAD

  def head
    HEAD.sub(/@lang@/, @info.lang)
  end

  def tail
    '</package>'
  end
META = <<EOS_META
  <metadata xmlns:dc="http://purl.org/ec/elements/1.1/>
    <dc:identifier id="book-id">
    urn:uuid:@uuid@
    </dc:identifier>
    <dc:title>@title@</dc:title>
    <dc:language>@lang@</dc:language>
EOS_META

  def metadata
    s = META.sub(/@uuid@/, @info.uuid).
             sub(/@title@/, @info.title).
             sub(/@lang@/, @info.lang)
    if @info.author.is_a?(Array)
      @info.author.each do |author|
        s << "    <dc:creator>#{author}</dc:creator>\n"
      end
    else
      s << "    <dc:creator>#{@info.author}</dc:creator>\n"
    end
    s << '  </metadata>'
  end

  def manifest
    s = "  <manifest>\n"
    s << "#{BookItem.new(@info.cover, 'cimage')}\n"
    s << "#{BookItem.new('nav.xhtml', 'nav')}\n"
    s << @items.map {|item| item.to_s }.join("\n")
    s << "\n  </manifest>"
  end

  def spine
    s = "  <spine>\n"
    @spine.each { |id| s << %Q[      <itemref idref="#{id}" />\n] }
    s << '  </spine>'
  end
end

end