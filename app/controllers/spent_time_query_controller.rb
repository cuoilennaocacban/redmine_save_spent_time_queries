class SpentTimeQueryController < ApplicationController

  before_filter :authorize, :except => [:new, :new_report, :index, :delete, :save]
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  include SpentTimeQueryHelper

  def index
    @project_id = params[:id]
    @filter = params[:filter]
    @queries = (User.current.admin && @filter == "all") ? SpentTimeQuery.includes(:user) : SpentTimeQuery.where('user_id = ? or is_public = true', User.current.id)
  end

  def new
    @project_id = params[:id]
    @query = nil
    begin
      @query = CGI.unescape(params[:v][:query])
    rescue
    end

    @current_query = nil
    if !@query.nil?
      @current_query = SpentTimeQuery.find_by_name(@query)
    end

  end

  def new_report
    @project_id = params[:id]

    @query = nil
    begin
      @query = CGI.unescape(params[:v][:query])
    rescue
    end

    @current_query = nil
    if !@query.nil?
      @current_query = SpentTimeQuery.find_by_name(@query)
    end

  end

  def delete
    query = SpentTimeQuery.find(params[:query_id])

    if query.user_id != User.current.id && !User.current.admin
      render_403
      return
    else
      query.delete
      project_id = params[:id]
      redirect_to :action => 'index', :id => project_id
      return
    end
  end

  def save
    project_id = params[:query][:project]
    report = params[:query][:type] == "details" ? "" : "/report"


    if project_id == ""
      value = Redmine::Utils::relative_url_root.to_s + '/time_entries' + report + '?' + params[:query][:value]
    else
      value = Redmine::Utils::relative_url_root.to_s + '/projects/' + project_id + '/time_entries' + report + '?' + params[:query][:value]
    end

    query = SpentTimeQuery.find_by_name(params[:query][:name])
    if not query.nil?

      if query.user_id != User.current.id && !User.current.admin
        render_404
        return
      else
        query.query = value
        query.name = params[:query][:new_name]
        query.is_public = params[:query][:is_public]

        if !User.current.admin
          query.user_id = User.current.id
        end

        query.save
      end
    else
      query = SpentTimeQuery.create(
          :name => params[:query][:new_name],
          :query => value,
          :is_public => params[:query][:is_public],
          :user_id => User.current.id
      )
    end

    redirect_to :action => 'index'
    return
  end
end