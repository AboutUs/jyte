class HelpController < ApplicationController
  
  def index
    @title = "Help!"
  end
  
  def cred    
  end

  def cred_step_by_step
    @title = "Help: Giving cred, step by step"
  end

  def claims_step_by_step
    @title = "Help: Making a claim, step by step"
  end

end
