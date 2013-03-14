# == Schema Information
#
# Table name: theories
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  chapter_id :integer
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Theory do
  before { @theo = FactoryGirl.build(:theory) }

  subject { @theo }

  it { should respond_to(:title) }
  it { should respond_to(:content) }
  it { should respond_to(:position) }
  it { should respond_to(:chapter) }

  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { @theo.title = " " }
    it { should_not be_valid }
  end
  describe "when title is too long" do
    before { @theo.title = "a" * 256 }
    it { should_not be_valid }
  end

  # Content
  describe "when content is not present" do
    before { @theo.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { @theo.content = "a" * 8001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { @theo.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { @theo.position = -1 }
    it { should_not be_valid }
  end
  describe "when position is already taken with the same chapter" do
    before { FactoryGirl.create(:theory,
                                chapter: @theo.chapter,
                                position: @theo.position) }
    it { should_not be_valid }
  end
  describe "when position is already taken with a different chapter" do
    before { FactoryGirl.create(:theory,
                                position: @theo.position) }
    it { should be_valid }
  end

end
