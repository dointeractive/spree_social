Spree.user_class.class_eval do
  has_many :user_authentications, :dependent => :destroy

  devise :omniauthable

  def apply_omniauth(omniauth)
    if email.blank?
      self.email = omniauth['info']['email'].presence || "#{self.class.generate_token(:persistence_token)}@temp.temp"
    end
    self.first_name = omniauth['info']['first_name'] if first_name.blank? && omniauth['info']['first_name'].present?
    self.last_name = omniauth['info']['last_name'] if last_name.blank? && omniauth['info']['last_name'].present?
    
    user_authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (user_authentications.empty? || !password.blank?) && super
  end
end
