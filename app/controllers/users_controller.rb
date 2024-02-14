class UsersController < ApplicationController
  def index
    current_user_age = current_user.age
    current_user_gender = current_user.gender
    @matched_reviews = Review.joins(:user).where(users: { age: current_user_age, gender: current_user_gender })
  end

  def show
    @user = current_user
  end
end
