require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

class ReviewsController < ApplicationController
    def index
      @reviews = Review.all
      if params[:url].present?
        get_data
      end

      @api = get_goo_api
    end

    def new
      @review = Review.new
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

    def get_data
      @contents = []
      n = 1
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.111 Safari/537.3"
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
    end

    def get_goo_api
      url = URI.parse('https://labs.goo.ne.jp/api/morph')
      app_id = ENV['goo_key']
      request_id = 'record001'
      sentence = '私は野球をする'
      info_filter = 'form' # 表記のみ取得する

      body = {
      app_id: app_id,
      request_id: request_id,
      sentence: sentence,
      info_filter: info_filter
      }

      response = Net::HTTP.post(url, body.to_json, 'Content-Type' => 'application/json')
      result = JSON.parse(response.body)
      word_list = result['word_list']
      word_list.each do |sentence|
        sentence.each do |word|
          puts word.first
        end
      end
    end

end
