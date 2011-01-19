module Wippr::User
  class Account < Wippr::Couch::CouchBase

    property :handle
    property :first_name, :default => ""
    property :last_name, :default => ""

    property :admin, :default => false

    property :facebook_uid
    property :twitter_uid
    property :linkedin_uid
    property :google_uid

    property :email
    property :password
    property :password_confirmation

    property :avatar
    property :mailbox

    property :unread_messages, :default => 0


    timestamps!

    view_by :handle
    view_by :facebook_uid
    view_by :twitter_uid
    view_by :email

    validates_uniqueness_of :handle
    validates_presence_of :handle, :email, :password


    def id
      self['_id']
    end

    def isAdmin?
      self['admin']
    end

    def assignMailBox
      mailbox = Wippr::Mail::MailBox.new
      mailbox.save!
      self.mailbox = mailbox.id
    end

  end
end


