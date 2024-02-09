require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

class ReviewsController < ApplicationController
    def index
      @url = params[:url]
      if @url.present?
        @sentence = get_data.join
        @api = get_goo_api(@sentence)
        @api = remove_hiragana_emoji_symbol_words(@api).join[0,500]
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

    # HTML タグを取り除いてテキストに変換する関数
    def strip_html_tags(html)
      Nokogiri::HTML.fragment(html).text
    end

    def formatting_url(url, n)
      url.sub(/pageNumber=\d+/, "pageNumber=#{n}")
    end

    #分析にほぼ不要なひらがな２文字以下、絵文字、記号の要素を削除する
    def remove_hiragana_emoji_symbol_words(array)
      array.reject! do |str|
        str.match?(/[^\p{Han}\p{Hiragana}\p{Katakana}\p{Alnum}\s]/) ||
        str.match?(/\A[\p{hiragana}]{1,2}\z/)
      end
    end
    
    #レビュー文１つ１つを要素とした１次元配列を返す
    def get_data
      @contents = []
      n = 1
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
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
    def get_goo_api(sentence)
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
