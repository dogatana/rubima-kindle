require 'rubima'
require 'fileutils'

filename_table = {}

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
    open("../fixed/#{new_file}", 'w:utf-8').write(new_html)
  else
    FileUtils.cp(file, '../fixed/' + new_file)
  end
end

FileUtils.cp_r('theme', '../fixed')
FileUtils.cp('../rubima.css', '../fixed/theme/rubima')
