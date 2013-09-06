Spree.user_class.class_eval do
  has_many :user_authentications, :dependent => :destroy

  attr_reader :avatar_remote_url
  attr_accessor :omniauth_save

  devise :omniauthable

  def apply_omniauth(omniauth)
    self.omniauth_save = true
    if email.blank?
      self.email = omniauth['info']['email'].presence || "#{self.class.generate_token(:persistence_token)}@temp.temp"
    end
    self.firstname = omniauth['info']['first_name'] if firstname.blank? && omniauth['info']['first_name'].present?
    self.lastname = omniauth['info']['last_name'] if lastname.blank? && omniauth['info']['last_name'].present?
    if !avatar.exists?
      image = omniauth['extra']['raw_info']['photo_big'].presence || omniauth['info']['image']
      self.avatar_remote_url = image if image.present?
    end
    user_authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def avatar_remote_url=(url)
    begin
      self.avatar = URI.parse(url)
      @avatar_remote_url = url
    rescue
    end
  end
end
