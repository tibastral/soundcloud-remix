class RemixesController < ApplicationController

  before_filter :login_required, :except => [:index, :show]

  def index
    @remixes = Remix.paginate :page => params[:page], :order => params[:sort] || "created_at DESC"
  end

  def show
    @remix = Remix.find(params[:id])
    @page_title = "#{@remix.user.name} - #{@remix.title}"
  end

  def new
    @remix = Remix.new
    @page_title = "Upload Your Remix"
  end

  def create
    
    respond_to do |format|
      format.html{ 
        @remix = Remix.new(:user_id => current_user[:id], :file => params[:remix][:file], :title => params[:remix][:title])
      }
      format.js{ 
        @remix = Remix.new(:user_id => current_user[:id], :file => params[:Filedata], :title => params[:title])
      }
    end
    
    new_track = current_user.soundcloud.Track.new
    new_track.title = @remix.title
    new_track.asset_data = @remix.file
    new_track.artwork_data = File.new("#{RAILS_ROOT}/public/images/artwork.jpg")
    new_track.description = SETTINGS["remix"]["description"]
    new_track.sharing = "public"
    new_track.tag_list = SETTINGS["remix"]["tag_list"]
    new_track.track_type = "remix"
    
    if new_track.save
      
      @remix.track_id = new_track.id
      @remix.save
      
      new_track.purchase_url = vote_url(@remix.id)
      
      i = 0
      
      while i == 0 do
        
        if new_track.save
          
          i = 1
          current_user.token.put("/groups/#{SETTINGS["group_id"]}/contributions/#{new_track.id}")
          
        else
          
          sleep 2
          
        end
        
      end
      
      respond_to do |format|
        format.html{ 
          flash[:notice] = 'Remix was successfully uploaded. It will show up here once created on SoundCloud.'
          redirect_to remix_url(@remix)
        }
        format.js{
          render :update do |page|
            page << "top.location.href = '#{remix_path(@remix)}';"
          end
        }
      end
      
    else
      
      render :action => "new"
      
    end
    
  end
  
  def status
    
    remix = Remix.find(params[:id])
    
    if remix.available?
    
      render :update do |page|
        page << "check_var = false;"
        page.replace_html 'processor', :partial => "player", :locals => {:remix => remix}
      end
    
    else
      
      render :nothing => true
      
    end
    
  end

end
