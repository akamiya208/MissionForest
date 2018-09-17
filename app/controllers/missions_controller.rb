# coding: utf-8
class MissionsController < ApplicationController
  before_action :set_mission, only: [:show, :edit, :update, :destroy]
  
  # GET /missions
  def index
    #@missions = Mission.order(created_at: :desc).all
    #@missions = Mission.all
    @missions = []
    Mission.order(created_at: :desc).all.each do |mission|
      puts(mission.id)
      puts(mission.root_task)
      root_task = mission.root_task
      notify = root_task.notify
      if (notify == 'own' or notify == 'organize') and root_task.user.id != current_user.try(:id)
          next
      end
      @missions.push(mission)
    end
    #@missions = Mission.order(created_at: :desc).all
  end

  # GET /missions/1
  def show
    @mission = Mission.find(params[:id])
#    @mission.hierarchy = get_hierarchy(@mission)
    authorize! @mission
  end

  # GET /api/missions/1/tasks
  def show_tasks
    @mission = Mission.find(params[:id])
    authorize! @mission
    all_tasks = @mission.tasks
    hierarchy = get_hierarchy(@mission)
    taskjson = {all_tasks: all_tasks, hierarchy: hierarchy}
    #    render :json => hierarchy
    render :json => taskjson
  end


  # DELETE /api/missions/1/participant/2
  def participation_user
    @mission = Mission.find(params[:mission_id])
    authorize! @mission

    @participation = Participation.new
    @participation.user = User.find(params[:user_id])
    @participation.mission = @mission

    if @participation.save
      render :json => {participation: @participation}
    end
  end
  
  # GET /missions/new
  def new
    authorize!
    @mission = Mission.new
    @mission.tasks.build
  end

  # GET /missions/1/edit
  def edit
    @mission = Mission.find(params[:id])
    authorize! @mission
  end

  # POST /missions
  def create
    authorize!
    @mission = Mission.new(mission_params)
    @mission.user = current_user
    if @mission.save
      @task = Task.new(root_task_params)
      @task.user = current_user
      @task.mission = @mission
      @task.direct_mission = @mission
      @mission.tasks[0] = @task
      #@mission.tasks.create(root_task_params)
      #@mission.tasks[0].user = current_user
      #@mission.tasks[0].direct_mission = @mission
      #if @mission.tasks[0].save
      if @task.save
        redirect_to mission_path(@mission), notice: 'ミッションが作成されました'
      else
        render :new
      end
    else
      render :new
    end
  end

  # POST /api/missions/create
  def api_create
    if params[:isdebug] == 'True'
      render :json => {'mission_id' => 10}
    else
      authorize!
      @mission = Mission.new(mission_params)
      @mission.user = current_user
      if @mission.save
        @task = Task.new(root_task_params)
        @task.user = current_user
        @task.mission = @mission
        @task.direct_mission = @mission
        if params[:issecret] != 'True'
          @task.notify = :lod
        end
        @mission.tasks[0] = @task
        if @task.save
          render :json => {'mission_id' => @mission.id}
        end
      end
    end
  end

  # PATCH/PUT /missions/1
  def update
    authorize! @mission
    
    if @mission.update(mission_params)
      redirect_to mission_path(@mission), notice: 'ミッションが更新されました'
    else
      render :edit
    end
  end

  # DELETE /missions/1
  def destroy
    authorize! @mission
    
    @mission.destroy
    redirect_to missions_path, notice: 'ミッションが削除されました'
  end

  # GET /missions/1/add_admin
  def add_admin
    @mission = Mission.find(params[:id])
    authorize! @mission
  end

  # PATCHPUT /missions/1/add_admin_update
  def add_admin_update
    @mission = Mission.find(params[:id])
    authorize! @mission

    user_name = params[:admin]
    
    user = User.find_by(name: user_name)
    @mission.admins.push(user)
    
    if @mission.save
      redirect_to mission_path(@mission), notice: user_name + 'さんが参加しました'
    else
      render :mission_add_admin
    end
  end

  # DELETE /api/missions/1/delete_admin/1
  def api_delete_admin
    @mission = Mission.find(params[:id])
    authorize! @mission

    @mission.admins.delete(params[:user_id])

    if @mission.save
      render :json => {'mission_id' => @mission.id, 'admin_id' => params[:user_id]}
    end
  end


  

  # GET /missions/1/add_participant
  def add_participant
    @mission = Mission.find(params[:id])
    authorize! @mission
  end

  # PATCHPUT /missions/1/add_participant_update
  def add_participant_update
    @mission = Mission.find(params[:id])
    authorize! @mission

    user_name = params[:participant]
    
    user = User.find_by(name: user_name)
    @mission.participants.push(user)
    
    if @mission.save
      redirect_to mission_path(@mission), notice: user_name + 'さんが参加しました'
    else
      render :mission_add_participant
    end
  end

  # DELETE /api/missions/1/delete_participant/1
  def api_delete_participant
    @mission = Mission.find(params[:id])
    authorize! @mission

    @mission.participants.delete(params[:user_id])

    if @mission.save
      render :json => {'mission_id' => @mission.id, 'participant_id' => params[:user_id]}
    end
  end

  private
  def get_hierarchy(mission)
    def generate_tree(task)
      tree = {}
      
      notify = task.notify
      if (notify == 'own' or notify == 'organize') and task.user.id != current_user.try(:id)
        return nil
      end
      
      
      tree["id"] = task.id
      tree["name"] = task.title
      tree["description"] = task.description
      tree["deadline_at"] = task.deadline_at
      tree["status"] = task.status
      tree["notify"] = notify

      
      if ! task.subtasks[0].nil? then
        tree["children"] = []
        task.subtasks.each do |child|
          childtree = generate_tree(child)
          
          if ! childtree.nil? then
            tree["children"].push(childtree)
          end
        end
      end
      return tree
    end

    task = mission.root_task
    tree = generate_tree(task)
    return tree
  end
  
  def set_mission
    @mission = Mission.find(params[:id])
  end
  
  def mission_params
    params[:mission].permit(:title, :description)
  end
  
  def root_task_params
    params[:mission].permit(:title, :description)
  end
end
