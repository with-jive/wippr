require "models/couch/couch_base"
class Wippr::Forum < Wippr::Couch::CouchBase
  
  unique_id :slugger

  
  view_by :order, :descending => false
  view_by :_id
  view_by :all, :created_at, :descending => false
  
  property :title
  property :description
  property :order

  property :posts_num, :default => 0
  property :last_post_author 
  property :last_post_title 
  property :last_post_date

  timestamps!
  
  validates_uniqueness_of :slugger
  validates_presence_of :title
  validates_presence_of :description


  def update_view date, author, title
    self['last_post_date'] = date
    self['last_post_author'] = author
    self['last_post_title'] = title
  end

  # Called upon for each model creation to generate a :unique_id handle.
  # Slugs the title attribute into a nice web-url friendly formato-
  def slugger
    self['title'].downcase.gsub(/[^a-z0-9]/, '-').squeeze('-').gsub(/^\-|\-$/,'')
  end

  # Triggered by child posts upon post deletion.
  # Updates view statistics and any following dependencies
  def update_view_upon_deletion! post_title
    # check if we actually need to update the view
    if self.last_post_title == post_title
        post = Wippr::Post.by_forum_id_and_created_at(
                :startkey => [self.id, "3"],
                :endkey => [self.id, "1"]).first
      self.update_view post.created_at, post.last_author_handle, post.title
      self.save!
    end
  end

  
  
end
