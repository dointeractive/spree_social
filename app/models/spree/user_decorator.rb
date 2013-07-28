Spree.user_class.class_eval do
  has_many :user_authentications, :dependent => :destroy

  attr_reader :avatar_remote_url

  devise :omniauthable

  def apply_omniauth(omniauth)
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

  def password_required?
    (user_authentications.empty? || !password.blank?) && super
  end

  def avatar_remote_url=(url)
    begin
      self.avatar = URI.parse(url)
      @avatar_remote_url = url
    rescue
    end
  end
end
