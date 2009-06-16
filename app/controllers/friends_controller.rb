class FriendsController < ApplicationController
  
  before_filter :logged_in
  
  def index
    @person = Person.find(params[:person_id])
    session[:profile_navi] = 'friends'
    save_navi_state(['own', 'friends']) if current_user?(@person)
    @friend_view = true
    # @friends = get_friends(@person)
    @friends = @person.friends(session[:cookie]).paginate :page => params[:page], :per_page => per_page
  end

  def create
    @friend = Person.find(params[:person_id])
    @successful = add_as_friend(@friend)
    render :update do |page|
      if @successful
        page["#{@friend.id}_friendstatus"].replace_html :partial => 'people/friend_status_link', 
                                                        :locals => { :person => @friend }
      end       
      refresh_announcements(page)
    end  
  end
  
  def destroy
    @friend = Person.find(params[:id])
    @successful = remove_from_friends(@friend)
    @friend_view = params[:friend_view]
    if @friend_view
      @person = Person.find(params[:friend_view_person])
      if current_user?(@person)
        @own_friend_view = true
        @friends = @person.friends(session[:cookie]).paginate :page => params[:page], :per_page => per_page
      end  
    end  
    render :update do |page|
      if @successful 
        page["#{@friend.id}_friendstatus"].replace_html :partial => 'people/friend_status_link', 
                                                        :locals => { :person => @friend }
        if @own_friend_view
          page["friend_view"].replace_html :partial => "friends/friend_view"
        end                                         
      end       
      refresh_announcements(page)
    end
  end
  
  private
  
  def add_as_friend(friend)
    begin
      @current_user.add_as_friend(friend.id, session[:cookie])
      flash[:notice] = :friend_requested
      return true
    rescue RestClient::ResourceNotFound => e
      flash[:error] = :friend_request_failed
      return false
    end
  end
  
  def remove_from_friends(friend)
    begin
      @current_user.remove_from_friends(friend.id, session[:cookie])
      flash[:notice] = :friend_removed
      return true
    rescue RestClient::ResourceNotFound => e
      flash[:error] = :removing_friend_failed
      return false
    end
  end

end
