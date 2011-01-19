require "models/couch/couch_base"
require 'date'
class Wippr::Post < Wippr::Couch::CouchBase

  provides_collection :forum_posts, 'Post', 'by_forum_id', :descending => true

  view_by :forum_id, :descending => true
  view_by :forum_id, :created_at, :descending => true
  view_by :forum_id, :updated_at, :descending => true
  view_by :slug
  
  property :forum_title
  property :forum_id
  property :title
  property :slug
  property :author_handle
  property :author_id


  property :replies, :default => 0
  property :views, :default => 0
  property :last_author_handle
  property :last_author_id

  validates_presence_of :title, :slug, :author_handle, :forum_id
  

  timestamps!
  
  def slug
    self['slug'] ||= self['title'].downcase.gsub(/[^a-z0-9]/, '-').squeeze('-').gsub(/^\-|\-$/,'')
  end

  def decrement_replies
    self['replies'] = self['replies'] - 1
  end

  def increment_replies
    self['replies'] = self['replies'] + 1
  end

  # Call when deleting random child messages.
  # Takes care of updating the last author regardless
  # if you affected it with a delete or not
  def update_post_author! deleted_author
    if self.last_author_id == deleted_author
      puts "Updating last author tag on post :: " + self['slug']
      message =  Wippr::Message.by_post_id_and_created_at(
              :startkey => [self.slug, "3"],:endkey => [self.slug, "1"],:descending => true).first

      puts "Message is \n" + message.to_s
      # update self dependencies
      self.last_author_handle = message.author_handle
      self.last_author_id = message.author_id
      self.update_timestamp message.created_at
      self.save!
      puts "updating parent_forum_view"
      self.update_parent_forum_view
    else
      self.save!
      puts "last_author is still valid"
    end

  end

  # Responsible for updating any parent view dependencies
  # Such as view statistics
  def update_parent_forum_view
      # update parent dependencies
      parent_forum = Wippr::Forum.get(self.forum_id)
      # give the parent this title to decide if updating is necessary
      parent_forum.update_view_upon_deletion! self.title
  end

  def update_timestamp date=nil
    if date
      write_attribute(:created_at, date)
    else
      write_attribute(:created_at, get_the_date)
    end
  end

  def delete_post_and_messages!
    messages = Wippr::Message.by_post_id(:key => self['slug'])
    if messages.nil?
      raise Exception
    end

    if messages.kind_of?(Array)
      puts "\n Deleting Message collection.. \n"
      Wippr::Couch::CouchBase.delete_docs messages
    else
      puts "\n Deleting Message Singular.. \n"
      Wippr::Couch::CouchBase.delete_doc messages
    end
    
    Wippr::Couch::CouchBase.delete_doc self
    # clean up any parent view changes that we affected
    self.update_parent_forum_view

  end


end
