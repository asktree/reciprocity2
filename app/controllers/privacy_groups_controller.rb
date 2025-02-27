class PrivacyGroupsController < ApplicationController
  before_action :set_privacy_group, only: [:show, :edit, :update, :destroy]

  # GET /privacy_groups
  # GET /privacy_groups.json
  def index
    @privacy_groups = current_user.privacy_groups
    @show_fb_import = current_user.facebook_token && !@privacy_groups.find{|group| group.name == "Facebook Friends"}
  end

  # GET /privacy_groups/1
  # GET /privacy_groups/1.json
  def show
    @current_user = current_user
    @members = @privacy_group.privacy_group_members
    ineligible_user_ids = @members.map(&:user_id) << @privacy_group.owner_id
    @member_users = @members.map{ |member| member.user }
    @eligible_users = User.where.not(id: ineligible_user_ids)
    # @eligible_users = User.where.not(id: current_user.id)
  end

  # GET /privacy_groups/new
  def new
    @privacy_group = PrivacyGroup.new
  end

  #This method is a total violation of RESTful API - this should probably be fixed but I wanted to get the logic to work
  # Also this code is still buggy - I need to figure out why if you delete the facebook friends then try to recreate them, ActiveRecord chokes
  # MAybe it has to do with not being RESTful
  def facebook
    if (current_user && current_user.facebook_token)
      @privacy_group = PrivacyGroup.create_facebook_group(current_user.facebook_token)
    end
    respond_to do |format|
      if @privacy_group
        format.html { redirect_to privacy_groups_url, notice: 'Privacy group was successfully created.' }
      else
        format.html { redirect_to privacy_groups_url, notice: 'Privacy group was not created.' }
      end
    end
  end

  # GET /privacy_groups/1/edit
  def edit
    @members = @privacy_group.
      privacy_group_members.joins(:user).pluck("users.id, users.name")
    ineligible_user_ids = @members.map(&:first) << @privacy_group.owner_id
    @eligible_non_members = User.where.not(id: ineligible_user_ids).pluck(:id, :name)
  end

  # POST /privacy_groups
  # POST /privacy_groups.json
  def create
    @privacy_group = PrivacyGroup.new(privacy_group_params)

    respond_to do |format|
      if @privacy_group.save
        format.html { redirect_to @privacy_group, notice: 'Privacy group was successfully created.' }
        format.json { render :show, status: :created, location: @privacy_group }
      else
        format.html { render :new }
        format.json { render json: @privacy_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /privacy_groups/1
  # PATCH/PUT /privacy_groups/1.json
  def update
    respond_to do |format|
      if @privacy_group.update(privacy_group_params)
        format.html { redirect_to @privacy_group, notice: 'Privacy group was successfully updated.' }
        format.json { render :show, status: :ok, location: @privacy_group }
      else
        format.html { render :edit }
        format.json { render json: @privacy_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /privacy_groups/1
  # DELETE /privacy_groups/1.json
  def destroy
    @privacy_group.destroy
    respond_to do |format|
      format.html { redirect_to privacy_groups_url, notice: 'Privacy group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_privacy_group
      @privacy_group = PrivacyGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def privacy_group_params
      params.require(:privacy_group).permit(:name, :owner_id)
    end
end
