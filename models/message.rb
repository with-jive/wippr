class Wippr::Message < Wippr::Couch::CouchBase
  
  property :author_handle
  property :author_id
  property :avatar_url
  property :forum_id
  property :post_id
  property :post_title
  property :message
  property :order
  property :root, :default => false

#  view_by :post_id, :forum_id, :descending => true
  view_by :post_id, :created_at
  view_by :post_id
  view_by :_id

  validates_presence_of :author_handle, :forum_id, :message
  
  property :last_edited
  property :edited_by

  timestamps!

  # Slugify the title while setting the slug property
  def slug
    self['slug'] = self['title'].downcase.gsub(/[^a-z0-9]/, '-').squeeze('-').gsub(/^\-|\-$/,'')
  end

  

  
end
