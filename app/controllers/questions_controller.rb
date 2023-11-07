#encoding: utf-8
class QuestionsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :manage_items, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order, :put_online, :update_explanation]
  
  before_action :get_question, only: [:edit, :update, :destroy]
  before_action :get_question2, only: [:manage_items, :order, :put_online, :explanation, :update_explanation]
  before_action :get_chapter, only: [:new, :create]
  
  before_action :user_that_can_update_chapter
  before_action :offline_question, only: [:destroy]

  # Create a question (show the form)
  def new
    @question = Question.new
    if params[:qcm] == '1'
      @question.is_qcm = true
    end
  end

  # Update a question (show the form)
  def edit
    if !@question.decimal
      @question.answer = @question.answer.to_i
    end
  end

  # Create a question (send the form)
  def create
    @question = Question.new(:online      => false,
                             :chapter     => @chapter,
                             :statement   => params[:question][:statement],
                             :level       => (@chapter.section.fondation? ? 0 : params[:question][:level]),
                             :explanation => "À écrire")
    if params[:question][:is_qcm] == '1'
      @question.is_qcm = true
      @question.many_answers = (params[:question][:many_answers] == '1')
      @question.answer = 0
    else
      @question.is_qcm = false
      if params[:question][:decimal] == '1'
        @question.decimal = true
        @question.answer = params[:question][:answer].gsub(",",".").to_f
      else
        @question.decimal = false
        @question.answer = params[:question][:answer].gsub(",",".").to_i
      end
    end
    before = 0
    unless @chapter.questions.empty?
      need = @chapter.questions.order('position').last
      before = need.position
    end
    @question.position = before + 1
    if @question.save
      flash[:success] = "Exercice ajouté."
      if @question.is_qcm
        redirect_to question_manage_items_path(@question)
      else
        redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
      end
    else
      render 'new'
    end
  end

  # Update a question (send the form)
  def update
    @question.statement = params[:question][:statement]
    unless @question.online
      @question.level = (@chapter.section.fondation? ? 0 : params[:question][:level])
      if @question.is_qcm
        if params[:question][:many_answers] == '1'
          @question.many_answers = true
        else
          if @question.many_answers
            # Must check there is only one true
            i = 0
            @question.items.order(:id).each do |c|
              if c.ok
                if i > 0
                  flash[:info] = "Attention, il y avait plusieurs réponses correctes à cet exercice, seule la première a été gardée."
                  c.update_attribute(:ok, false)
                end
                i = i+1
              end
            end
            if @question.items.count > 0 && i == 0
              # There is no good answer
              flash[:info] = "Attention, il n'y avait aucune réponse correcte à cet exercice, une réponse correcte a été rajoutée aléatoirement."
              @item = @question.items.order(:id).first
              @item.update_attribute(:ok, true)
            end
          end
          @question.many_answers = false
        end
      else
        if params[:question][:decimal] == '1'
          @question.decimal = true
          @question.answer = params[:question][:answer].gsub(",",".").to_f
        else
          @question.decimal = false
          @question.answer = params[:question][:answer].gsub(",",".").to_i
        end
      end
    end
    
    if @question.save
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    else
      render 'edit'
    end
  end

  # Delete a question
  def destroy
    @question.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Show page to manage items of a qcm
  def manage_items
  end

  # Move a question to a new position
  def order
    question2 = @chapter.questions.where("position = ?", params[:new_position]).first
    if !question2.nil? and question2 != @question
      res = swap_position(@question, question2)
      flash[:success] = "Exercice déplacé#{res}." 
    end
    redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
  end

  # Put a question online
  def put_online
    @question.update_attribute(:online, true)
    @section = @question.chapter.section
    @section.update_attribute(:max_score, @section.max_score + @question.value)
    redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
  end

  # Update the explanation of a question (show the form)
  def explanation
  end

  # Update the explanation of a question (send the form)
  def update_explanation
    if @question.update(:explanation => params[:question][:explanation]) # Do not use update_attribute because it does not trigger validations
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    else
      render 'explanation'
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the question
  def get_question
    @question = Question.find_by_id(params[:id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  # Get the question (v2)
  def get_question2
    @question = Question.find_by_id(params[:question_id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
  end
  
  ########## CHECK METHODS ##########

  # Check that the question is offline
  def offline_question
    return if check_online_object(@question)
  end
  
end
