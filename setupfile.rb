require 'rubima'
require 'fileutils'
require 'forwardable'

class FileTable
  extend Forwardable
  def_delegators :@hash, :keys, :each
  
  def initialize
    @hash = {}
  end
  
  def [](key)
    @hash[key.downcase]
  end
  
  def []=(key, val)
    @hash[key.downcase] = val
  end
end

dest_dir = if ARGV.empty?
             'kindle'
           else
             ARGV[0].encode('utf-8')
           end

filename_table = FileTable.new

puts "# collecting file information"
Dir.glob('*').each do |file|
  next unless File.file?(file)
  new_file = Rubima::Setup::unescape_name(file)
  if Rubima::html_file?(file) && file !~ /\.html$/i
    new_file += '.html'
  end
  filename_table[file] = new_file
end

filename_table.each do |file, new_file|
  next if file =~ /^prep?\-/
  puts "# processing #{file}"
  if new_file =~ /\.html$/i
    html = open(file, 'r:utf-8', &:read)
    new_html = Rubima::Setup::fix_html(html, filename_table)
    open("../#{dest_dir}/#{new_file}", 'w:utf-8').write(new_html)
  else
    FileUtils.cp(file, "../#{dest_dir}/" + new_file)
  end
end

FileUtils.cp_r('theme', "../#{dest_dir}")
FileUtils.cp('../rubima.css', "../#{dest_dir}/theme/rubima")
FileUtils.cp('theme/rubima/rubima_logo_l.png', "../#{dest_dir}/cover.png")
