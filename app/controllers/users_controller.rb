class UsersController < ApplicationController
  before_action :is_matching_login_user, only: [:show]
  def index
    @active_nav = :recommendation
    current_user_age = current_user.age
    current_user_gender = current_user.gender
    @matched_reviews = Review.joins(:user).where(users: { age: current_user_age, gender: current_user_gender })
    @index = "index"
  end

  def show
    @active_nav = :mypage
    @user = current_user
  end

  private

  def is_matching_login_user
    user = User.find(params[:id])
    unless user.id == current_user.id
      redirect_to user_path(current_user.id)
    end
  end

end
