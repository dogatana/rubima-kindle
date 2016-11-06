# Rubyist Magazine Kindle 化

## 改訂履歴
Oct. 26, 2016 - 初版公開    
Oct. 28, 2016 - README.md のTypo修正とLinuxでsetupfileが失敗するのを修正  
Nov. 6, 2016 - ダウンロードファイル時の保存ファイル名の変更。Issue #5 の対策

----
## Nov. 6, 2016 の変更内容
#### **1. ダウンロード時の保存ファイル名の変更について**
ダウンロードファイルのうち、'p=' および 'f=' を含むファイルは、(恐らく '=' を含むため) Windowsのコマンドプロンプトでの扱いが面倒になっているので、'p=' は 'p_' へ、 'f=' は削除したものを保存ファイル名として使用するように変更しています。  
ダウンロード済みのローカルファイルは rake download とすることで、ネットワークのアクセスなしに新ファイル名へ変更されるので、改めてダウンロードしなおす必要はありません。

#### **2. 表示デバイスの解像度の違いによる図形表示サイズの調整について(Issue #5)**  
Issue #5 にある通り、表示デバイスの解像度によって図形(png, jpg)の実際の表示サイズが小さくなり、見づらくなる場合があります。例えば Kindle HDX 8.9 は 339ppi の解像度で、写真はともかく、
31号 『るりまサーチの作り方 - Ruby 1.9 で groonga 使って全文検索』 の記事にあるスライド画像は非常に見づらい状況。
この対処として拡大率を指定したmobiファイルを作成可能にしました。  
具体的には rake MAG=2.2 のように指定します。  
拡大率は ARGV[0].to_f で  処理される。なお、1.0以下の場合は指定なしとして扱います。  
一旦作成した後に拡大率を変更したい場合は
  - rake setupfile
  - rake mobi MAG=2

などと、rake setupfile から再度実行してください。

Kindle HDX8.9(339ppi) の場合、2.2 くらいが丁度良いようです。  
文字の表示サイズとのバランスもあるので、好みの拡大率を選択してください。

#### **3. 一部の png ファイルの表示が崩れる件について(Issue #6)**  
使用されいてる png ファイルのフォーマット（色深度、カラータイプ）を Kindlegen もしくは Kindleが扱えないために発生していると推測しています。  
該当するファイルは
- p_0010-CodeReview_pukipa.png          
- p_0010-CodeReview_pukiwikiparser.png  

の2つ。Issue #6 に記載のとおり、download フォルダ内のこれらのファイルのフォーマットを変更することで正しく表示できます。私の場合はWindowsの画像変換フリーソフトで変更しました。Linux だと ImageMagick でしょうか。

----

## はじめに

Rubyist Magazine の Web ページ
http://magazine.rubyist.net/ で公開されている Rubyist Magazine をmobiファイル（Amazon Kindleの電子書籍フォーマット）へ変換するものです。

## 対象となるRubyist Magazine
- 現時点(2016年10月)では創刊号から54号まで
- 一応 index.html の読み出し結果から検索しているので、新しい号が追加されても大丈夫なはず

## 必要なもの
- Kindlegen
  - amazon のWebページからダウンロードし、PATHを通しておくこと
- gem
  - Nokogiri
  - FastImage

## 利用方法

1. コマンドプロンプトから rake を実行する  
  - 拡大率を指定する場合は rake MAG=<拡大率> のように指定する。
  - 例）拡大率 2.2 を指定する場合 => rake MAG=2.2
2. しばらくすると kindle フォルダに rubima.mobi が作成される
  - kindlegenで警告が出ますが、mobiファイルは作成されています
3. Kindle へ転送する
4. Kindle で読む


## ダウンロード時間について

- Webページからのダウンロードの際、1ファイルのダウンロード毎に1秒のウェイトを取っています。
全部で2700ファイルほどダウンロードするので、気長に待ってください。


## ライセンス

rubyスクリプトは　MIT ライセンスです。

~~~
MIT License

Copyright (c) Toshihiko Ichida 2016

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
~~~

new_rubima.css は ruby ライセンスです。

~~~
/*
.css: Hiki theme for Rubyist Magazine.

ただただしさんの「ruby-lang.css: tDiary theme for ruby-lang.org.」を
ベースに作成しました。
オリジナルテーマ作者のただただしさんに感謝します。

You can redistribute it and/or modify it under the same term as Ruby.

Copyright 2004 (C) by TADA Tadashi <sho@spc.gr.jp>
Copyright 2004 (C) by Yamamoto Dan <dan@dgames.jp>
*/
~~~
