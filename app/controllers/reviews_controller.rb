require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'uri'
require_relative '../services/chat_gpt_service'

class ReviewsController < ApplicationController
    def index
      @active_nav = :analysis
      @review = Review.new
      @url = params[:url]
      if @url.present?
        headers = setting_headers()
        @image_url = get_image_url(@url, headers)
        all_views_url = get_all_views_link(@url,headers,'#reviews-medley-footer > div.a-row.a-spacing-medium > a')
        url_for_next_page = get_next_page_link(all_views_url,headers,'#cm_cr-pagination_bar > ul > li.a-last > a')
        if url_for_next_page != "nothing"
          type_of_page = "multiple_pages"
          @formated_url = remove_unnecessary_literal(url_for_next_page)
        else
          type_of_page = "single_page"
          @formated_url = convert_url(all_views_url)
        end
      end

      if @formated_url.present?
        @sentence = scrape_data(@formated_url,headers, type_of_page).join
        if @sentence.nil?
          @sentence = scrape_data(@formated_url,headers, type_of_page).join
        end
        if @sentence.nil?
          @sentence = scrape_data(@formated_url,headers, type_of_page).join
        end
        @api = get_morphological_analysis(@sentence)
        # joinする文字数はいったん600(長すぎるとエラー)
        @api = remove_hiragana_emoji_symbol_words(@api).join[0,600]
        if @api.nil?
          @ans = "分析に失敗しました。もう一度分析してください。"
        else
          prompt = "下記のレビューにおいて、ユーザーがよかった思うこと、失敗したことは何か説明して##{@api}"
          chatgpt = ChatGptService.new
          @ans = chatgpt.chat(prompt)
        end
        @product = extract_product_name(@formated_url)
      end
    end

    def create
      @review = Review.new(review_params)
      @review.user_id = current_user.id
      if @review.save
        redirect_to reviews_path
      else
        render :index
      end
    end

    def destroy
      review = Review.find(params[:id])
      review.destroy
      redirect_to reviews_path
    end

    private

    def review_params
      params.require(:review).permit(:review, :link, :product_name, :image_url)
    end

    private

    # HTMLタグを取り除いてテキストに変換する関数
    def strip_html_tags(html)
      Nokogiri::HTML.fragment(html).text
    end

    def remove_unnecessary_literal(url)
      url = url.gsub("&reviewerType=all_reviews", "")
    end

    def convert_url(url)
      url = url.gsub("ref=cm_cr_dp_d_show_all_btm?ie=UTF8&reviewerType=all_reviews", "ref=cm_cr_arp_d_paging_btm_next_2?ie=UTF8&reviewerType=all_reviews&pageNumber=1")
    end

    # 次のページに遷移するために必要なメソッド
    def formatting_url(url, n)
      url = url.sub(/pageNumber=\d+/, "pageNumber=#{n}")
    end

    # ユーザーが入力したurlから商品名を抜き出すメソッド
    def extract_product_name(url)
      url = url.split("/")
      idx_amazon = url.index("www.amazon.co.jp")
      encoded_string = url[idx_amazon + 2]
      product_name = URI.decode_www_form_component(encoded_string)
      return product_name
    end

    #分析にほぼ不要なひらがな２文字以下、絵文字、記号の要素を削除する
    def remove_hiragana_emoji_symbol_words(array)
      array.reject! do |str|
        str.match?(/[^\p{Han}\p{Hiragana}\p{Katakana}\p{Alnum}\s]/) ||
        str.match?(/\A[\p{hiragana}]{1,2}\z/)
      end
    end
    
    def get_all_views_link(url,headers,selector)
      html = URI.open(url, headers).read
      doc = Nokogiri::HTML(html)
      begin
        link = doc.css(selector).attr('href').value
        proper_link = "https://www.amazon.co.jp/#{link}"
      rescue OpenURI::HTTPError,StandardError,Timeout::Error => e
      # 商品によっては「レビューをすべて見る」ボタンのセレクタが「reviews-medley-footer > div.a-row.a-spacing-medium > a」ではなく「cr-pagination-footer-0 > a」の場合があるので例外処理
        begin
          proper_link = get_all_views_link(url,headers,'#cr-pagination-footer-0 > a')
        rescue OpenURI::HTTPError,StandardError,Timeout::Error => e
          proper_link = "invalid link"
        end
      end

      return proper_link
    end

    def get_next_page_link(url,headers,selector)
      html = URI.open(url, headers).read
      doc = Nokogiri::HTML(html)
      begin
        link = doc.css(selector).attr('href').value
        proper_link = "https://www.amazon.co.jp/#{link}"
      rescue OpenURI::HTTPError,StandardError,Timeout::Error => e
      # レビュー数が少ないと「次へ」ボタンがない場合がある。そのままだとエラーが起こるので、その場合は代わりにレビューの1ページ目を格納するようにする
        proper_link = get_all_views_link(url,headers,'#cm_cr-pagination_bar > ul > li.a-last > a')
      end
      
      return proper_link
    end

    def get_image_url(url,headers)
      begin
        html = URI.open(url, headers).read
        doc = Nokogiri::HTML(html)
        image_tag = doc.at_css('#imgTagWrapperId img')
        image_url = image_tag['src'] if image_tag
      rescue OpenURI::HTTPError,StandardError,Timeout::Error => e
        image_url = nil
      end
      return image_url
    end

    #レビュー文１つ１つを要素とした１次元配列を返す
    def scrape_data(url,headers,type_of_page)
      @contents = []
      n = 1
      while true do
        url = formatting_url(url, n)
        begin
          html = URI.open(url, headers).read
          doc = Nokogiri::HTML.parse(html)
          reviews = doc.css('div.a-row.a-spacing-small.review-data')
          break if reviews.empty?
          @contents.concat(reviews)
          n += 1
        rescue OpenURI::HTTPError,StandardError,Timeout::Error => e
          @error = [e,url]
          break
        end
      end
      @contents.map! { |html| strip_html_tags(html) }
      return @contents
      return @error if @error
    end

    #形態素解析し得た文字列を要素とする1次元配列を返す
    def get_morphological_analysis(sentence)
      url = URI.parse('https://labs.goo.ne.jp/api/morph')
      app_id = ENV['goo_key']
      request_id = 'record001'
      info_filter = 'form'

      body = {
      app_id: app_id,
      request_id: request_id,
      sentence: sentence,
      info_filter: info_filter
      }

      response = Net::HTTP.post(url, body.to_json, 'Content-Type' => 'application/json')
      time = 0
      while response == true or time <= 20 do
        sleep 1
        time += 1
      end

      result = JSON.parse(response.body)
      if result['word_list'].nil?
        word_list = ["レビュー","なし"]
      else
        word_list = result['word_list'].flatten
      end

      return word_list
    end

    def setting_headers
      user_agents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:90.0) Gecko/20100101 Firefox/90.0',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36',
  ]

      referrers = [
    'https://narou-osusume.com/osusumes/2',
    'https://narou-osusume.com/osusumes/10',
    'https://narou-osusume.com/osusumes/15'
  ]
      
      user_agent = user_agents.sample
      referrer = referrers.sample
      headers = {
    'User-Agent' => user_agent,
    'Referer' => referrer
  }
      return headers
    end

end
