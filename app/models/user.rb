class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,:authentication_keys => [:name]
  
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :name, length: { in: 2..20 }
  has_many :reviews, dependent: :destroy
  has_many :favorites, dependent: :destroy
  enum age: { "10代": 1, "20代": 2, "30代": 3, "40代": 4, "50代": 5, "60代": 6, "70代": 7, "80代": 8, "90代以上": 9 }
  enum gender: { 男: 1, 女: 2 }

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if username = conditions.delete(:name)
      where(conditions).where(name: username).first
    else
      where(conditions).first
    end
  end


  def email_required?
    false
  end
  def email_changed?
    false
  end
  def will_save_change_to_email?
    false
  end
end
