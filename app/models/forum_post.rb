class ForumPost < ApplicationRecord
  has_paper_trail

  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user
  #has_many :reactions, as: :reactable # not sure this is used anywhere, seems to break ability to soft delete

  has_many :flagged_items, as: :flaggable

  has_many :replies, as: :commentable, class_name: 'Comment'

  has_many :likes, as: :likeable

  validates :user_id, :body, presence: true

  scope :sorted, ->{ order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  scope :not_open, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state != ?', 'pending')
  }

  scope :open, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state = ?', 'pending')
  }

  scope :not_accepted, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state != ?', 'remove')
  }

  scope :accepted, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state = ?', 'remove')
  }

  scope :not_rejected, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state != ?', 'keep')
  }

  scope :rejected, -> {
    left_outer_joins(:flagged_items).where('flagged_items IS NULL OR flagged_items.aasm_state = ?', 'keep')
  }

  def solve_forum_thread
    forum_thread.update(solved: true)
  end

  def parent
    forum_thread
  end
end
