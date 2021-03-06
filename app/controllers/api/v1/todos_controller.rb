class Api::V1::TodosController < ApplicationController
  before_action :authorize_request
  before_action :find_user
  before_action :check_ownership, except: :index
  before_action :find_todo, except: [:create, :index]
  before_action :check_if_is_done, only: :update

  # GET /todos
  def index
    is_owner = @current_user.id == @user.id
    filtered_todos = FilterTodos.filter(@user, params, is_owner)
    render json: filtered_todos, status: :ok
  end

  # POST /todos
  def create
    @todo = Todo.new(todo_params)
    @todo.user = @user
    if @todo.save
      render json: @todo, status: :created
    else
      render json: { errors: @todo.errors.full_messages },
              status: :unprocessable_entity
    end
  end

  # PUT /todos/{id}
  def update
    unless @todo.update(todo_params)
      render json: { errors: @todo.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  # DELETE /todos/{id}
  def destroy
    @todo.destroy
  end

  private

  def check_if_is_done
    if @todo.is_done && (params[:is_done].nil? || ActiveModel::Type::Boolean.new.cast(params[:is_done]))
      render json: { errors: "cannot update done tasks, unmark to edit" }, status: :unprocessable_entity
    end
  end

  def find_todo
    @todo = @user.todos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'todo not found' }, status: :not_found
  end

  def find_user
    @user = User.find_by_username!(params[:user__username])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'user not found' }, status: :not_found
  end

  def todo_params
    params.permit(
      :title, :description, :is_done, :is_public
    )
  end
end
