# Rubyist Manzine Kindle 化

## はじめに

Rubyist Magazine の Web
http://magazine.rubyist.net/ で公開されている Rubyist Magazine のmobiファイル（Amazon Kindleの電子書籍フォーマット）へ変換するものです。

## 必要なもの
- Kindlegen
- amazon のWebページからダウンロードし、PATHを通しておくこと

## 利用方法

1. コマンドプロンプトから rake を実行する
2. しばらくすると kindle フォルダに rubima.mob が作成される
3. Kindle へ転送する
4. Kindle で読む

## ダウンロードについて時間について

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
