module SnippetsSystem
  
  def self.included(base)
    base.helper_method :snippet
  end
  
  def snippet(name)
    unless output = read_fragment("snippet_#{name}");
      snippet = Snippet.find_by_name(name);
      if snippet
        write_fragment("snippet_#{name}", snippet.content)
        return snippet.content
      else
        #Snippet.create({:name => name, :content => ''})
        # WTF? the code on the previous line makes ActiveRecord do this:
        # INSERT INTO snippets ("cachable_flag", "content") VALUES('t', E'')
        # 
        # Have I finally gone crazy or is this really the worst piece of shit that I've ever worked with?
        # Do this instead, fuck this terrible excuse for a framework.
        
        # There should be no need to escape the value in name as it was declared in the physical layout file
        # and cannot be injected externally.
        Snippet.connection.execute %{INSERT INTO snippets(name, content) VALUES ('#{name}', '')}
        expire_fragment(/snippet_.*/)
        return ''
      end
    else
      return output
    end
  end
end