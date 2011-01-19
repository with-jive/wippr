class Session < Wippr::Couch::CouchBase
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
#  devise :database_authenticatable, :registerable,
#         :recoverable, :rememberable, :trackable, :validatable
#
  property :provider, Wippr::Expando::AuthProvider
  


end
