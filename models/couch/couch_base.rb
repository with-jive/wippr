module Wippr::Couch
  class CouchBase < CouchRest::Model::Base
    #config initialise
    if development?
      puts "Using development Database..."
      @@wipnation = CouchRest.database!("https://user:password@host/wippr_development")
    else
      @@wipnation = CouchRest.database!("https://user:password@host/wippr_production")
    end
    
    use_database @@wipnation
    
    def self.delete_doc doc
      doc.destroy
    end

    def self.delete_docs docs
      for doc in docs
        puts "\n Deleting a doc.."
        doc.destroy
      end
    end

  end
end
