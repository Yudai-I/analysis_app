require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'uri'
require_relative '../services/chat_gpt_service'

class ReviewsController < ApplicationController
    def index
      @url = params[:url]
      if @url.present?
        @sentence = scrape_data.join
        @api = get_morphological_analysis(@sentence)
        # joinする文字数はいったん600(長すぎるとエラー)
        @api = remove_hiragana_emoji_symbol_words(@api).join[0,600]
        prompt = "#{@api}+下記のレビューにおいて、ユーザーがよかった思うこと、失敗したことは何ですか？"
        chatgpt = ChatGptService.new
        @ans = chatgpt.chat(prompt)
        @product = extract_product_name(@url)
      end
    end

    def create
      @review = Review.new(review_params)
      if @review.save
        redirect_to reviews_path
      else
        render :new
      end
    end

    def destroy
      review = Review.find(params[:id])
      review.destroy
      redirect_to reviews_path
    end

    private

    def review_params
      params.require(:review).permit(:review)
    end

    private

    # HTMLタグを取り除いてテキストに変換する関数
    def strip_html_tags(html)
      Nokogiri::HTML.fragment(html).text
    end

    def formatting_url(url, n)
      url.sub(/pageNumber=\d+/, "pageNumber=#{n}")
    end

    # ユーザーが入力したurlから商品名を抜き出すメソッド
    def extract_product_name(url)
      url = url.split("/")
      idx_amazon = url.index("www.amazon.co.jp")
      encoded_string = url[idx_amazon + 1]
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
    
    #レビュー文１つ１つを要素とした１次元配列を返す
    def scrape_data
      @contents = []
      n = 1
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.112 Safari/537.3"
      while true do
        url = params[:url]
        formated_url = formatting_url(url, n)
        begin
          html = URI.open(formated_url, "User-Agent" => user_agent).read
          doc = Nokogiri::HTML.parse(html)
          reviews = doc.css('div.a-row.a-spacing-small.review-data')
          break if reviews.empty?
          @contents.concat(reviews)
          n += 1
        rescue OpenURI::HTTPError, Timeout::Error => e
          break
        end
      end
      @contents.map! { |html| strip_html_tags(html) }
      return @contents
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
      result = JSON.parse(response.body)
      word_list = result['word_list']
      #flattenは2次元配列を1次元配列にするメソッド(データを扱いやすいように)
      return word_list.flatten
    end

end
