module Wippr::Mail
  #noinspection ALL
  class MailBox < Wippr::Couch::CouchBase

    property :unreads, :default => 0
    # contains letter mappings
    # :subject, :from_id, :letter_id, :date, :read
    property :inbox, [Hash]
    property :outbox, [Hash]
    property :notices, [Hash]


    view_by :_id
    

    def add_to_inbox subject, from, id
      inboxee = Hash.new
      inboxee[:subject] = subject
      inboxee[:from_id] = from
      inboxee[:letter_id] = id
      inboxee[:read] = false
      inboxee[:date] = get_the_date
      self.unreads += 1
      self.inbox.unshift inboxee
    end

    def add_to_outbox subject, to, id
      outboxee = Hash.new
      outboxee[:subject] = subject
      outboxee[:to_id] = to
      outboxee[:letter_id] = id
      outboxee[:date] = get_the_date

      self.outbox.push outboxee
    end

    def assign_mailbox who
      user = Wippr::User::Account.by_handle(:key=>who).first
      user.mailbox = self.id
      user.save!
    end


    def update_message_read id
      self.inbox.each do |letter|
        if letter["letter_id"] == id
          letter["read"] = true
          return
        end
      end
    end

    def get_the_date
      DateTime.now.strftime("%I:%M%p | %m/%d/%y")
    end

  end
end
