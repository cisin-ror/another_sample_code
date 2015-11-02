class ClassificationsController < ApplicationController
  load_and_authorize_resource :classification

  before_filter :redirect_if_reached_to_maximum, only: [:new, :create, :clone]

  def index
    respond_to do |format|
      format.html
      format.json { render :text => @categories.to_json, :status => :ok }
    end
  end

  def show
    respond_to do |format|
      format.json { render :text => @classification.to_json, :status => :ok }
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
     if @classification.save
        format.html do
          redirect_to edit_classification_classification_current_experience_path(@classification)
        end
        format.js
        format.json { render :text => @classification.to_json, :status => :created }
      else
        format.html { render :new }
        format.json { render :text => @classification.errors.to_json, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @parent = @classification.parent
    respond_to do |format|
      format.js
      format.html
    end
  end

   def clone
    @new_classification = @classification.clone_classification_with_its_associations(current_user)
    flash[:notice] = t(:classification_msg)  if @new_classification.present?
    respond_to do|format|
      format.html { redirect_to resource_path(@classification.portfolio) }
    end
  end

protected

  def redirect_if_reached_to_maximum
    @resource = @classification.resource
    redirect_to resouce_path(@resource) if @resource.exceed_max_limit_for_classifications?
  end
end