module PaginateHelper
  def paginate(collection, *args)
    if collection.is_a? WillPaginate::Collection
      return will_paginate(collection,args.extract_options!)
    else 
      return nil
    end
  end
end