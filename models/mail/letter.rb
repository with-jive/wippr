module Wippr::Mail
  class Letter < Wippr::Couch::CouchBase

    property :mailbox_id
    property :unread, :default => true


    property :from_user_id
    property :to_user_id

    property :subject
    property :body

    property :created_at

    view_by :id
    view_by :mailbox_id, :updated_at


    validates_presence_of :body, :from_user_id, :to_user_id

    def send! my_mailbox_id
      recipient =  self.from_user_id
      user = Wippr::User::Account.by_handle(:key => recipient).first
      user.unread_messages += 1
      user.save!

      self.mailbox_id = user.mailbox
      self.save!

      to_mailbox = Wippr::Mail::MailBox.get(user.mailbox)

      to_mailbox.add_to_inbox self.subject, self.from_user_id, self.id
      to_mailbox.save!

      my_mailbox = Wippr::Mail::MailBox.get(my_mailbox_id)
      my_mailbox.add_to_outbox self.subject, self.to_user_id, self.id
      my_mailbox.save!
    end

    def update_read_dependency
      mailbox = Wippr::Mail::MailBox.get(self.mailbox_id)
      if mailbox.unreads != 0
        mailbox.unreads -= 1
        mailbox.update_message_read self.id
        mailbox.save!
      end

    end



  end

end
