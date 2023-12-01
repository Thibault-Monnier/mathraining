# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestcorrections/_show.html.erb", type: :view, contestcorrection: true do

  let(:user) { FactoryGirl.create(:user) }
  let!(:contestproblem) { FactoryGirl.create(:contestproblem, status: :corrected) }
  let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, official: false, score: 4) }
  let!(:contestsolution_official) { contestproblem.contestsolutions.where(:official => true).first }
  
  before do
    contestproblem.contest.organizers << user
    assign(:contestproblem, contestproblem)
    assign(:contest, contestproblem.contest)
    assign(:signed_in, true)
    assign(:current_user, user)
  end
  
  context "if the solution is official" do
    it "renders the solution, not the score, but the form" do
      render partial: "contestcorrections/show", locals: {contestsolution: contestsolution_official, contestcorrection: contestsolution_official.contestcorrection, can_edit_correction: true}
      expect(rendered).to have_no_selector("h4", text: "Score obtenu")
      expect(rendered).to have_no_content("/ 7")
      expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution_official.contestcorrection, kind: "contestcorrection", can_edit: true})
      expect(response).to render_template(:partial => "contestcorrections/_edit", :locals => {can_edit_correction: true})
    end
  end
  
  context "if the solution is not official" do
    context "if the contestproblem is already corrected" do
      it "renders the solution and the score, but not the form" do
        render partial: "contestcorrections/show", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection, can_edit_correction: false}
        expect(rendered).to have_selector("h4", text: "Score obtenu")
        expect(rendered).to have_content("#{contestsolution.score} / 7")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution.contestcorrection, kind: "contestcorrection", can_edit: false})
        expect(response).not_to render_template(:partial => "contestcorrections/_edit", :locals => {can_edit_correction: false})
      end
    end
    
    context "if the contestproblem is in correction" do
      before do
        contestproblem.in_correction!
      end
      
      it "renders the solution, the score and the form" do
        render partial: "contestcorrections/show", locals: {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection, can_edit_correction: true}
        expect(rendered).to have_selector("h4", text: "Score obtenu")
        expect(rendered).to have_content("#{contestsolution.score} / 7")
        expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution.contestcorrection, kind: "contestcorrection", can_edit: true})
        expect(response).to render_template(:partial => "contestcorrections/_edit", :locals => {can_edit_correction: true})
      end
    end
  end
end
