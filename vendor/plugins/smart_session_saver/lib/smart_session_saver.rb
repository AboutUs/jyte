# Don't write unchanged sessions to store.
# Brian Ellin - brian -at- janrain.com

class CGI::Session::ActiveRecordStore::Session  

  # Special version of @data which keeps a copy of the orig
  # session data for comparison before save.
  def data
    @data ||= self.class.unmarshal(read_attribute(@@data_column_name)) || {}
    # keep a *deep* copy of the session data
    @data_copy ||= self.class.unmarshal(read_attribute(@@data_column_name)) || {}
    @data
  end

  # Has the session data changed?
  def needs_saving?
    return false unless loaded?
    return @data != @data_copy
  end

end

class CGI::Session::ActiveRecordStore
  
  # Version of close that hooks in with sesion container's
  # needs_saving? method.
  def close
    if @session
      if @session.needs_saving?
        update
      end
      @session = nil
    end
  end
end
