# wget 後のファイルを名前を変更しながら別フォルダへコピー
#
require 'rubima'
require 'fileutils'

Dir.glob('magazine.rubyist.net/index.html@*').each do |file|
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
