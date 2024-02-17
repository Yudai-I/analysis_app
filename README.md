# Amazon分析
https://analysis-app.onrender.com

## 概要
amazon上に掲載されている商品を、リンクの貼り付けとボタンの1クリックでレビュー文を分析できるアプリです。
### 背景(製品開発のきっかけ、課題等）
amazon上にあるレビューは人によって意見が多種多様で、結局ある商品についてどんな意見がまとめられるのか分かりにくいという課題を感じました。
そこで、スクレイピングとChatGPTを活用して手軽に、有用な情報を得るという手段を作りたいと思ったことがきっかけです。
### 製品説明（具体的な製品の説明）
まずはAmazon公式ページにアクセスします。そして任意の商品ページのリンクを取得後、分析用のページに設置されたテキストボックスにそのリンクを貼り付けて分析ボタンを押します。
そうすると、分析結果が得られて、気に入ればマイページに保存しておくことが可能です。また、ユーザー登録時に年代と性別を登録するようにしていて、これをもとにレコメンドページでおすすめの商品とそのレビュー分析結果を見ることができます。
### 特長
#### 1. 特長1
手軽に大量のレビューを分析することができる
#### 2. 特長2
分析結果とともに、商品情報をマイページに保存しておくことができる
#### 3. 特長3
ユーザー登録時の情報に基づいたレコメンドを受けることができる

### 解決出来ること
気になる商品のレビューを見てみたけど、結局どんな商品か伝わらなかった。強みが分からなかった。そんな問題への解決に役立つと考えます。
### 今後の展望
・全体的に、よりモダンで整ったフロントエンド実装をすること(Hotwireを検討)
・レコメンドページ・機能の改良
### 注力したこと（こだわり等）
・形態素解析で分析に不要な文字列や絵文字を削除することにより、ChatGPT APIの利用料金を節約しながらより多くのレビューを分析できるように実装したこと
・その場の分析だけで終わらないようにマイページに保存できるようにしたり、レコメンドを受けることができるようにしたこと
## 開発技術
### 活用した技術・フレームワーク・ライブラリ・モジュール
Ruby 3.1.4
Rails 7.0.8
Bootstrap 5.2
Nokogiri(スクレイピング)
Devise(認証)
gooラボ API(形態素解析)

#### デバイス
* PC・タブレット
