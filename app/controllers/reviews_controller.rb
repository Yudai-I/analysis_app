require 'nokogiri'
require 'open-uri'

class ReviewsController < ApplicationController
    def index
      @reviews = Review.all
      @contents = []
      n = 1
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.111 Safari/537.3"
      while true do
        url = "https://www.amazon.co.jp/%E3%80%90Amazon-co-jp%E9%99%90%E5%AE%9A%E3%80%91-%E3%82%B1%E3%83%AD%E3%83%83%E3%82%B0-%E7%B2%92%E6%84%9F%E3%81%97%E3%81%A3%E3%81%8B%E3%82%8A-%E3%82%AA%E3%83%BC%E3%83%88%E3%83%9F%E3%83%BC%E3%83%AB%E3%81%94%E3%81%AF%E3%82%93-900g/product-reviews/B0BVYG4YGW/ref=cm_cr_getr_d_paging_btm_next_2?ie=UTF8&reviewerType=all_reviews&pageNumber=1"
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

end
