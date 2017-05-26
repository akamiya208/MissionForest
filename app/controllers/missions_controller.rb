# coding: utf-8
# coding: utf-8
class MissionsController < ApplicationController
  before_action :set_mission, only: [:show, :edit, :update, :destroy]
  
  # GET /missions
  def index
    @missions = Mission.order(created_at: :desc).all
  end

  # GET /missions/1
  def show
    @mission = Mission.find(params[:id])
  end

  # GET /api/missions/1/tasks
  def show_tasks
    def get_name(hash)
      task_id = hash["id"]
      task = Task.find(task_id)
      hash["name"] = task.title
      hash["description"] = task.description
      hash["deadline_at"] = task.deadline_at
      hash["status"] = task.status
      if ! hash["children"].nil? then
        hash["children"].each do |child|
          get_name(child)
        end
      end
    end
    
    mission = Mission.find(params[:id])
    hierarchy = mission.hierarchy
    if hierarchy.nil? then
      task = Task.find_by(mission_id: params[:id])
      hierarchy = {}
      hierarchy["id"] = task.id
      hierarchy["children"] = []
      input_hierarchy = hierarchy.to_json
      mission.hierarchy = input_hierarchy
      mission.save
      hierarchy["name"] = task.title
      hierarchy["description"] = task.description
      hierarchy["deadline_at"] = task.deadline_at
      hierarchy["status"] = task.status
      render :json => hierarchy
    else
      hierarchy = JSON.parse(hierarchy)
      get_name(hierarchy)
      render :json => hierarchy
    end
  end
  
  # POST /api/missions/1/hierarchy
  def update_hierarchy
    mission = Mission.find(params[:id])
    mission.hierarchy = mission_params[:hierarchy]
    if mission.save
      render :json => { mission: mission }
    end
  end

  # GET /missions/new
  def new
    @mission = Mission.new
    @mission.tasks.build
  end

  # GET /missions/1/edit
  def edit
  end

  # POST /missions
  def create
    @mission = Mission.new(mission_params)
    @mission.user = current_user
    if @mission.save
      @mission.tasks.create(root_task_params)
      @mission.tasks[0].user = current_user
      if @mission.tasks[0].save
        redirect_to mission_path(@mission), notice: 'ミッションが作成されました'
      else
        render :new
      end
    else
      render :new
    end
  end

  # PATCH/PUT /missions/1
  def update
    if @mission.update(mission_params)
      hierarchy = @mission.hierarchy
      hierarchy = JSON.parse(hierarchy)
      task_id = hierarchy["id"]
      @task = Task.find(task_id)
      if @task.update(root_task_params)
        redirect_to mission_path(@mission), notice: 'ミッションが更新されました'
      else
        render :edit
      end
    else
      render :edit
    end
  end

  # DELETE /missions/1
  def destroy
    @mission.destroy
    redirect_to missions_path, notice: 'ミッションが削除されました'
  end

  private
    def set_mission
      @mission = Mission.find(params[:id])
    end

    def mission_params
      params[:mission].permit(:title, :description, :hierarchy)
    end

    def root_task_params
      params[:mission].permit(:title, :description)
    end
end
